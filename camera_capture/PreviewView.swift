//
//  PreviewView.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/05/31.
//

import UIKit
import AVKit

/// カメラプレビューView
class PreviewView: UIView {
    
    /// キャプチャプレビューレイヤ
    public let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// プレビュー対象のキャプチャセッション
    public var session: AVCaptureSession? {
        get {
            videoPreviewLayer.session
        }
        
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup(){
        // カメラプレビューレイヤを生成・割り当て
        videoPreviewLayer.frame = bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(videoPreviewLayer)
    }

}
