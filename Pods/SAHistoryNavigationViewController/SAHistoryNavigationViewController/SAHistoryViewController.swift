//
//  SAHistoryViewController.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/03/26.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit
import MisterFusion

protocol SAHistoryViewControllerDelegate: class {
    func historyViewController(viewController: SAHistoryViewController, didSelectIndex index: Int)
}

class SAHistoryViewController: UIViewController {
    //MARK: static constants
    static private let LineSpace: CGFloat = 20.0
    static private let ReuseIdentifier = "Cell"
    
    //MARK: - Properties
    weak var delegate: SAHistoryViewControllerDelegate?
    weak var contentView: UIView?
    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    var images: [UIImage]?
    var currentIndex: Int = 0
    
    private var selectedIndex: Int?
    private var isFirstLayoutSubviews = true
    
    //MARKL: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit {
        contentView?.removeFromSuperview()
        contentView = nil
    }
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let contentView = contentView {
            view.addSubview(contentView)
            view.addLayoutSubview(contentView, andConstraints:
                contentView.Top,
                contentView.Bottom,
                contentView.Left,
                contentView.Right
            )
        }
        view.backgroundColor = contentView?.backgroundColor
        
        let size = UIScreen.mainScreen().bounds.size
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = size
            layout.minimumInteritemSpacing = 0.0
            layout.minimumLineSpacing = self.dynamicType.LineSpace
            layout.sectionInset = UIEdgeInsets(top: 0.0, left: size.width, bottom: 0.0, right: size.width)
            layout.scrollDirection = .Horizontal
        }
        
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: self.dynamicType.ReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clearColor()
        collectionView.showsHorizontalScrollIndicator = false
        
        view.addLayoutSubview(collectionView, andConstraints: 
            collectionView.Top,
            collectionView.Bottom,
            collectionView.CenterX,
            collectionView.Width |==| view.Width |*| 3
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLayoutSubviews {
            scrollToIndex(currentIndex, animated: false)
            isFirstLayoutSubviews = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: - Scroll handling
extension SAHistoryViewController {
    private func scrollToIndex(index: Int, animated: Bool) {
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: animated)
    }
    
    func scrollToSelectedIndex(animated: Bool) {
        guard let index = selectedIndex else { return }
        scrollToIndex(index, animated: animated)
    }
}

//MARK: - UICollectionViewDataSource
extension SAHistoryViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.dynamicType.ReuseIdentifier, forIndexPath: indexPath)

        let subviews = cell.subviews
        subviews.forEach {
            if let view = $0 as? UIImageView {
                view.removeFromSuperview()
            }
        }
    
        let imageView = UIImageView(frame: cell.bounds)
        imageView.image = images?[indexPath.row]
        cell.addSubview(imageView)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegate
extension SAHistoryViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        let index = indexPath.row
        selectedIndex = index
        delegate?.historyViewController(self, didSelectIndex:index)
    }
}