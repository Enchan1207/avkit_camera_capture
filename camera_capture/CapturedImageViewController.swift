//
//  CapturedImageViewController.swift
//  camera_capture
//
//  Created by EnchantCode on 2024/06/01.
//

import UIKit

/// キャプチャした画像を表示するViewController
class CapturedImageViewController: UIViewController {

    /// 表示する画像
    var image: UIImage?

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.image = image
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
}
