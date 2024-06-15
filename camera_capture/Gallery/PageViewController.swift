//
//  PageViewController.swift
//  pageviewcontroller
//
//  Created by EnchantCode on 2024/06/10.
//

import UIKit

class PageViewController: UIViewController {
    
    // MARK: - GUI components
    
    /// コンテンツを保持するビュー
    @IBOutlet private weak var contentImageView: UIImageView!
    
    // MARK: - Properties
    
    /// 自分自身のページ番号
    let pageIndex: Int

    /// 表示するコンテンツ
    let content: UIImage
    
    // MARK: - Initializers
    
    /// ページインデックスと表示内容を与えて初期化
    /// - Parameters:
    ///   - pageIndex: ページインデックス
    ///   - content: 表示内容
    init(pageIndex: Int, content: UIImage){
        self.pageIndex = pageIndex
        self.content = content
        super.init(nibName: "PageViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        print("page \(pageIndex) deinit")
    }
    
    // MARK: - View lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentImageView.image = self.content
    }
    
}
