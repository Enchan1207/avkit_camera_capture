//
//  ViewController.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/05/31.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    // MARK: - GUI Components
    
    /// 撮影ボタン
    @IBOutlet weak var captureButton: UIButton!
    
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
    
    // MARK: - View lifecycles, transitions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションを構成
        configureCaptureSession()
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
        // ボタンを無効化し、バッファの更新を停止
        captureButton.isEnabled = false
        shouldUpdateBuffer = false
        
        // バッファから画像をキャプチャしてリストに追加
        if let sampleBuffer = lastCapturedSampleBuffer,
           let image = createImage(sample: sampleBuffer) {
            print("Captured! \(image.size)")
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
            // TODO: ここフォーカスが変わったことを検知できたりするだろうか?
            previewView.focusedDevicePoint = at
        } catch {
            print("Failed to focus: \(error)")
        }
    }
    
}
