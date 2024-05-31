//
//  ViewController.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/05/31.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    /// キャプチャセッション
    private let session = AVCaptureSession()
    
    /// キャプチャプレビュー
    @IBOutlet weak var previewView: PreviewView! {
        didSet {
            previewView.videoPreviewLayer.session = session
        }
    }
    
    /// キャプチャ映像出力
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    /// 最後にキャプチャしたバッファ
    private var lastCapturedFrame: CMSampleBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションを構成
        configureCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // セッション開始
        DispatchQueue.global().async{[weak self] in
            self?.session.startRunning()
        }
    }
    
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
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// 新しいビデオフレームが書き込まれたとき
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        lastCapturedFrame = sampleBuffer
    }
    
}
