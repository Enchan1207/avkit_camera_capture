//
//  ViewController.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/05/31.
//

import UIKit
import Photos
import AVKit

class ViewController: UIViewController {
    
    // MARK: - GUI Components
    
    /// ギャラリーボタン
    @IBOutlet weak var galleryButton: UIButton!
    
    /// 撮影ボタン
    @IBOutlet weak var captureButton: UIButton!
    
    /// 倍率調整ボタン
    @IBOutlet weak var magnificationButton: UIButton!
    
    /// キャプチャプレビュー
    @IBOutlet weak var previewView: PreviewView! {
        didSet {
            previewView.session = session
            previewView.delegate = self
        }
    }
    
    // MARK: - Properties
    
    /// キャプチャセッション
    private let session = AVCaptureSession()
    
    /// キャプチャ映像出力
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    /// バッファを更新すべきか
    private var shouldUpdateBuffer = false
    
    /// 最後にキャプチャしたバッファ
    private var lastCapturedSampleBuffer: CMSampleBuffer?
    
    /// キャプチャした画像の配列
    private var capturedImages: [UIImage] = []
    
    /// ステータスバーを隠すか?
    override var prefersStatusBarHidden: Bool {true}
    
    /// ズーム開始時のスケール
    private var initialZoomFactor: CGFloat = 1.0
    
    /// 触覚フィードバックジェネレータ
    private let hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - View lifecycles, transitions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションを構成
        configureCaptureSession()
        
        // 触覚フィードバックを準備
        hapticFeedbackGenerator.prepare()
        
        // デバイスの向きの変更を検知する
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // セッション開始
        DispatchQueue.global().async{[weak self] in
            self?.session.startRunning()
            self?.shouldUpdateBuffer = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration methods
    
    /// キャプチャセッションを構成
    private func configureCaptureSession(){
        // 構成モードに入る
        session.beginConfiguration()
        
        // セッションプリセットを設定
        session.sessionPreset = .high
        
        // デフォルトのキャプチャデバイスを取得
        guard let device = AVCaptureDevice.default(for: .video),
              let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Failed to configure capture device")
        }
        
        // 入力を構成してセッションに追加
        if(session.canAddInput(deviceInput)){
            session.addInput(deviceInput)
        }
        
        // 映像データ出力をセッションに追加し、自身をデリゲートに設定
        if(session.canAddOutput(videoDataOutput)){
            session.addOutput(videoDataOutput)
            videoDataOutput.setSampleBufferDelegate(self, queue: .main)
        }
        
        // 構成を確定する
        session.commitConfiguration()
    }
    
    // MARK: - UI event handlers
    
    /// キャプチャボタンが押されたとき
    @IBAction func onTapCapture(_ sender: Any) {
        // 触覚フィードバックを生じる
        hapticFeedbackGenerator.impactOccurred()
        
        // ボタンを無効化し、バッファの更新を停止
        captureButton.isEnabled = false
        shouldUpdateBuffer = false
        
        // バッファから画像をキャプチャ
        if let sampleBuffer = lastCapturedSampleBuffer,
           let image = createImage(sample: sampleBuffer) {
            // リストに追加し、フォトライブラリに保存
            saveImageToPhotoLibrary(image)
            capturedImages.append(image)
        }
        
        // バッファの更新を再開し、ボタンを有効化して戻る
        shouldUpdateBuffer = true
        captureButton.isEnabled = true
    }
    
    /// ギャラリーボタンが押されたとき
    @IBAction func onTapGallery(_ sender: Any) {
        let galleryVC = GalleryViewController(images: capturedImages)
        present(galleryVC, animated: true)
    }
    
    /// 倍率切り替えボタンが押されたとき
    @IBAction func onTapMagnification(_ sender: Any) {
        
    }
    
    /// デバイスの向きが変わったとき
    @objc private func onDeviceOrientationChange(){
        setGalleryButtonOrientation()
    }
    
    // MARK: - Methods
    
    /// キャプチャしたサンプルバッファからUIImageを生成
    /// - Parameter sample: 生成元のバッファ
    /// - Returns: 生成された画像
    private func createImage(sample: CMSampleBuffer) -> UIImage? {
        // イメージバッファを取得し、CIImageに変換
        guard let imageBuffer = sample.imageBuffer else {return nil}
        let originalCIImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // レイヤに表示されている領域を取得し、originalImageを切り取る
        let videoPreviewLayer = previewView.videoPreviewLayer
        let layerRect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: videoPreviewLayer.visibleRect)
        let convertedLayerRect = layerRect.mapped(to: originalCIImage.extent.size)
        let croppedCIImage = originalCIImage.cropped(to: convertedLayerRect)
        
        // デバイスの向きを考慮しつつ、CIContext経由でUIImageに変換
        // ref: https://developer.apple.com/documentation/coreimage/ciimage/1437833-cropped
        let context = CIContext()
        guard let croppedCGImage = context.createCGImage(croppedCIImage, from: croppedCIImage.extent) else {return nil}
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: imageOrientation())
        return croppedImage
    }
    
    /// デバイスの向きから生成する画像の向きを取得
    /// - Parameter deviceOrientation: デバイスの向き
    /// - Returns: 画像の向き
    private func imageOrientation(_ deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
    
    /// デバイスの向きに合わせてギャラリーボタンの向きを変える
    /// - Parameter deviceOrientation: デバイスの向き
    private func setGalleryButtonOrientation(_ deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation){
        // 回転角を計算
        let angle: CGFloat
        switch deviceOrientation {
        case .portrait:
            angle = 0.0
        case .portraitUpsideDown:
            angle = .pi
        case .landscapeLeft:
            angle = .pi / 2
        case .landscapeRight:
            angle = -(.pi / 2)
        default:
            angle = 0.0
        }
        let transform = CGAffineTransform(rotationAngle: angle)
        
        // アニメーションさせる
        UIView.animate(withDuration: 0.2) {[weak self] in
            self?.galleryButton.transform = transform
        }
    }
    
    /// フォトライブラリに写真を保存する
    /// - Parameter image: 保存する画像
    private func saveImageToPhotoLibrary(_ image: UIImage){
        // TODO: クロージャじゃなくてｴｲｼﾝｸとか使う?
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                print("Photo library access denied")
                return
            }
            
            // 写真を保存
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if(success){
                    print("Photo saved")
                }else {
                    print("error: \(error!)")
                }
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// 新しいビデオフレームが書き込まれたとき
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard shouldUpdateBuffer else {return}
        lastCapturedSampleBuffer = sampleBuffer
    }
    
}

extension ViewController: PreviewViewDelegate {
    
    func previewView(_ view: PreviewView, didRequireFocus at: CGPoint) {
        // デバイスを取得
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device else {return}
        do {
            
            // フォーカスポイントを移動
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = at
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = at
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
            
            // プレビューViewのフォーカス位置を再設定
            previewView.focusedDevicePoint = at
        } catch {
            print("Failed to focus: \(error)")
        }
    }
    
    func previewView(_ view: PreviewView, didRequireZoom state: UIGestureRecognizer.State, to scale: CGFloat) {
        // デバイスを取得
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device else {return}
        
        // ズーム開始時のスケールを保持しておく
        if state == .began {
            initialZoomFactor = device.videoZoomFactor
        }
        
        // ジェスチャのスケールからデバイスに渡すスケールを計算し、受理可能な値にクリップする
        // なお最大スケールに関してはやたらデカい値が許容されるので、アプリ側で最大値を設けておく
        let newScale = initialZoomFactor * scale
        let minScale = device.minAvailableVideoZoomFactor
        let maxScale = min(device.maxAvailableVideoZoomFactor, 20.0)
        let clampedScale = min(max(newScale, minScale), maxScale)
        
        // (tentative) スケールボタンに値を設定
        let scaleString = String(format: "%.1f", clampedScale)
        magnificationButton.setTitle("\(scaleString)x", for: .normal)
        
        // デバイスに設定する
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedScale
            device.unlockForConfiguration()
        } catch {
            print("Failed to zoom: \(error)")
        }
    }
    
}
