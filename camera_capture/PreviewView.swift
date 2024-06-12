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
    
    // MARK: - Properties
    
    /// キャプチャプレビューレイヤ
    public let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// デリゲート
    weak var delegate: PreviewViewDelegate?
    
    /// プレビュー対象のキャプチャセッション
    public var session: AVCaptureSession? {
        get {
            videoPreviewLayer.session
        }
        
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: - Initializers

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
        videoPreviewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(videoPreviewLayer)
        setNeedsLayout()
        
        // ユーザのフォーカス指示を受け取る
        let focusGesture = UITapGestureRecognizer(target: self, action: #selector(onTapPreviewView))
        addGestureRecognizer(focusGesture)
    }
    
    // MARK: - View lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
    }
    
    // MARK: - Gesture handler
    
    @objc private func onTapPreviewView(_ gesture: UITapGestureRecognizer){
        // ユーザのタップ位置を取得し、レイヤ座標系に変換
        let viewTapPoint = gesture.location(in: self)
        let layerTapPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: viewTapPoint)
        
        // デリゲートに通知
        delegate?.previewView(self, didRequireFocus: layerTapPoint)
    }

}
