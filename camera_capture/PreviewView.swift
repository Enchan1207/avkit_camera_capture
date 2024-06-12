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
    
    /// フォーカス枠
    private var focusFrame = CAShapeLayer()
    
    /// デリゲート
    weak var delegate: PreviewViewDelegate?
    
    /// 現在フォーカスが当たっている点(デバイス座標系)
    var focusedDevicePoint: CGPoint? {
        didSet {
            if focusedDevicePoint != nil {
                updateFocusFrame(to: videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: focusedDevicePoint!))
            }else{
                removeFocusFrame()
            }
        }
    }
    
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
        
        // フォーカス枠を初期化
        initFocusFrame()
        layer.addSublayer(focusFrame)
        
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
    
    // MARK: - Methods
    
    /// フォーカス枠を初期化する
    private func initFocusFrame(){
        focusFrame = .init()
        focusFrame.strokeColor = UIColor.systemOrange.cgColor
        focusFrame.lineWidth = 1.5
        focusFrame.fillColor = UIColor.clear.cgColor
        focusFrame.opacity = 0.0
    }
    
    /// フォーカス枠の位置を更新する
    /// - Parameter layerPoint: レイヤ上のフォーカス位置
    private func updateFocusFrame(to layerPoint: CGPoint){
        // TODO: この辺りは完全にデザインの問題なので、いつかちゃんとやる
        let size: CGFloat = 100
        let rect = CGRect(x: layerPoint.x - size / 2, y: layerPoint.y - size / 2, width: size, height: size)
        focusFrame.path = UIBezierPath(rect: rect).cgPath
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // トランジション終了後に値が戻るのを防ぐ
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        focusFrame.add(animation, forKey: "opacity")
    }
    
    /// フォーカス枠を削除する
    private func removeFocusFrame(){
        focusFrame.opacity = 0.0
    }
    
}
