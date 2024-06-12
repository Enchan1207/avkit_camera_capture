//
//  PreviewViewDelegate.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/06/12.
//

import Foundation

protocol PreviewViewDelegate: AnyObject {
    
    /// ユーザがフォーカスを要求した(ビューをタップした)
    /// - Parameters:
    ///   - view: 対象のプレビューView
    ///   - at: タップ座標(レイヤ座標系)
    func previewView(_ view: PreviewView, didRequireFocus at: CGPoint)
    
}
