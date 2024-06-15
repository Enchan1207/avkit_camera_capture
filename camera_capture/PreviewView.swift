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
    
    // グリッド
    private var grid = CAShapeLayer()
    
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
        
        // グリッド枠を初期化
        initGrid()
        layer.addSublayer(grid)
        
        // フォーカス枠を初期化
        initFocusFrame()
        layer.addSublayer(focusFrame)
        
        setNeedsLayout()
        
        // ユーザのフォーカス指示を受け取る
        let focusGesture = UITapGestureRecognizer(target: self, action: #selector(onTapPreviewView))
        addGestureRecognizer(focusGesture)
        
        // ユーザのズーム指示を受け取る
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(onPinchPreviewView))
        addGestureRecognizer(zoomGesture)
    }
    
    // MARK: - View lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        grid.path = createGridLayer(size: bounds.size, numberOfRows: 3, numberOfCols: 3)
    }
    
    // MARK: - Gesture handler
    
    @objc private func onTapPreviewView(_ gesture: UITapGestureRecognizer){
        // ユーザのタップ位置を取得し、レイヤ座標系に変換
        let viewTapPoint = gesture.location(in: self)
        let layerTapPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: viewTapPoint)
        
        // デリゲートに通知
        delegate?.previewView(self, didRequireFocus: layerTapPoint)
    }
    
    @objc private func onPinchPreviewView(_ gesture: UIPinchGestureRecognizer){
        // 状態とスケールをデリゲートに通知
        delegate?.previewView(self, didRequireZoom: gesture.state, to: gesture.scale)
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
    
    /// グリッドを初期化する
    private func initGrid(){
        grid = .init()
        grid.strokeColor = UIColor.white.cgColor
        grid.lineWidth = 0.9
        grid.fillColor = UIColor.clear.cgColor
        grid.opacity = 0.9
    }
    
    /// グリッドレイヤを作成して返す
    /// - Parameters:
    ///   - size: 領域の大きさ
    ///   - rows: 縦区画数
    ///   - cols: 横区画数
    /// - Returns: 作成したグリッドレイヤ
    /// - Note: 区画数の数で分割されます(引かれる線分は指定した値-1本になります)。
    private func createGridLayer(size: CGSize, numberOfRows rows: UInt, numberOfCols cols: UInt) -> CGPath {
        let path = CGMutablePath()
        guard rows > 1, cols > 1 else {return path}
        
        // 1区画あたりの幅と高さを計算
        let unitWidth = size.width / .init(cols)
        let unitHeight = size.height / .init(rows)
        
        // 引く線分の座標リストを計算
        let lineXPositions = (1..<cols).map({unitWidth * .init($0)})
        let lineYPositions = (1..<rows).map({unitHeight * .init($0)})
        
        // それぞれについて move -> addLine
        lineXPositions.forEach({x in
            path.move(to: .init(x: x, y: 0))
            path.addLine(to: .init(x: x, y: size.height))
        })
        lineYPositions.forEach({y in
            path.move(to: .init(x: 0, y: y))
            path.addLine(to: .init(x: size.width, y: y))
        })
        
        return path
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
