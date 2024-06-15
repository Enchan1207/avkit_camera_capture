//
//  GalleryViewController.swift
//  pageviewcontroller
//
//  Created by EnchantCode on 2024/06/10.
//

import UIKit

class GalleryViewController: UIPageViewController {
    
    // MARK: - Properties
    
    /// ページに表示するコンテンツ
    let images: [UIImage]
    
    // MARK: - Initializers
    
    init(images: [UIImage]){
        self.images = images
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        
        self.dataSource = self
        if let firstVC = getPageViewController(at: 0) {
            self.setViewControllers(
                [firstVC],
                direction: .forward,
                animated: false)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - Methods
    
    /// 指定インデックスのビューコントローラを生成・取得する
    /// - Parameter index: インデックス
    /// - Returns: 生成されたVC
    private func getPageViewController(at index: Int) -> PageViewController? {
        guard images.indices.contains(index) else {return nil}
        let vc = PageViewController(pageIndex: index, content: images[index])
        return vc
    }
    
}

extension GalleryViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = (viewController as? PageViewController)?.pageIndex else {return nil}
        
        return getPageViewController(at: currentIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = (viewController as? PageViewController)?.pageIndex else {return nil}
        
        return getPageViewController(at: currentIndex + 1)
    }
    
}
