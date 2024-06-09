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
    
    /// キャプチャプレビュー
    @IBOutlet weak var previewView: PreviewView! {
        didSet {
            previewView.session = session
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
    private var lastCapturedFrame: CMSampleBuffer?
    
    /// ステータスバーを隠すか?
    override var prefersStatusBarHidden: Bool {true}
    
    // MARK: - View lifecycles, transitions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションを構成
        configureCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // セッション開始
        DispatchQueue.global().async{[weak self] in
            self?.session.startRunning()
            self?.shouldUpdateBuffer = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
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
        // バッファの更新を止める
        shouldUpdateBuffer = false
        
        // バッファから画像をキャプチャして表示
        if let frame = lastCapturedFrame {
            showCapturedImage(frame: frame)
        }
        
        // バッファの更新を再開して戻る
        shouldUpdateBuffer = true
    }
    
    // MARK: - Methods
    
    /// キャプチャした画像を取得し、表示する
    private func showCapturedImage(frame: CMSampleBuffer){
        
        // イメージバッファを取得し、CIImageに変換
        guard let imageBuffer = frame.imageBuffer else {return}
        let originalCIImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // レイヤに表示されている領域を取得し、originalImageを切り取る
        let videoPreviewLayer = previewView.videoPreviewLayer
        let layerRect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: videoPreviewLayer.visibleRect)
        let convertedLayerRect = layerRect.mapped(to: originalCIImage.extent.size)
        let croppedCIImage = originalCIImage.cropped(to: convertedLayerRect)
        
        // CIContext経由でUIImageに変換
        // ref: https://developer.apple.com/documentation/coreimage/ciimage/1437833-cropped
        let context = CIContext()
        guard let croppedCGImage = context.createCGImage(croppedCIImage, from: croppedCIImage.extent) else {
            fatalError("Failed to create CGImage")
        }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: .right)
        
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// 新しいビデオフレームが書き込まれたとき
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard shouldUpdateBuffer else {return}
        lastCapturedFrame = sampleBuffer
    }
    
}
