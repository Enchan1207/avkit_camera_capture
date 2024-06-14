//
//  PreviewViewDelegate.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/06/12.
//

import UIKit

protocol PreviewViewDelegate: AnyObject {
    
    /// ユーザがフォーカスを要求した(ビューをタップした)
    /// - Parameters:
    ///   - view: 対象のプレビューView
    ///   - at: タップ座標(レイヤ座標系)
    func previewView(_ view: PreviewView, didRequireFocus at: CGPoint)
    
    /// ユーザがズームを要求した(ビューをピンチした)
    /// - Parameters:
    ///   - view: 対象のプレビューView
    ///   - state: ズームジェスチャの状態
    ///   - scale: 要求された倍率
    func previewView(_ view: PreviewView, didRequireZoom state: UIGestureRecognizer.State, to scale: CGFloat)
    
}
