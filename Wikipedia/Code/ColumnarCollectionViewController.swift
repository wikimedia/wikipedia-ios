import UIKit

@objc(WMFColumnarCollectionViewController)
class ColumnarCollectionViewController: UICollectionViewController, Themeable {
    let layout: WMFColumnarCollectionViewLayout = WMFColumnarCollectionViewLayout()
    var theme: Theme = Theme.standard
    
    fileprivate var placeholders: [String:UICollectionReusableView] = [:]

    init() {
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.alwaysBounceVertical = true
        extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForPreviewingIfAvailable()
        if let selectedIndexPaths = collectionView?.indexPathsForSelectedItems {
            for selectedIndexPath in selectedIndexPaths {
                collectionView?.deselectItem(at: selectedIndexPath, animated: animated)
            }
        }
        if let visibleCells = collectionView?.visibleCells {
            for cell in visibleCells {
                guard let cellWithSubItems = cell as? SubCellProtocol else {
                    continue
                }
                cellWithSubItems.deselectSelectedSubItems(animated: animated)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForPreviewing()
    }
    
    // MARK - Cell & View Registration
   
    final public func placeholder(forCellWithReuseIdentifier identifier: String) -> UICollectionViewCell? {
        return placeholders[identifier] as? UICollectionViewCell
    }
    
    final public func placeholder(forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) -> UICollectionReusableView? {
        return placeholders["\(elementKind)-\(identifier)"]
    }
    
    @objc(registerCellClass:forCellWithReuseIdentifier:addPlaceholder:)
    final func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView?.register(cellClass, forCellWithReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let cellClass = cellClass as? UICollectionViewCell.Type else {
            return
        }
        let cell = cellClass.init(frame: view.bounds)
        cell.isHidden = true
        view.insertSubview(cell, at: 0) // so that the trait collections are updated
        placeholders[identifier] = cell
    }
    
    @objc(registerNib:forCellWithReuseIdentifier:)
    final func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        collectionView?.register(nib, forCellWithReuseIdentifier: identifier)
        guard let cell = nib?.instantiate(withOwner: nil, options: nil).first as? UICollectionViewCell else {
            return
        }
        cell.isHidden = true
        view.insertSubview(cell, at: 0) // so that the trait collections are updated
        placeholders[identifier] = cell
    }
    
    @objc(registerViewClass:forSupplementaryViewOfKind:withReuseIdentifier:addPlaceholder:)
    final func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView?.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let viewClass = viewClass as? UICollectionReusableView.Type else {
            return
        }
        let reusableView = viewClass.init(frame: view.bounds)
        reusableView.isHidden = true
        view.insertSubview(reusableView, at: 0) // so that the trait collections are updated
        placeholders["\(elementKind)-\(identifier)"] = reusableView
    }
    
    @objc(registerNib:forSupplementaryViewOfKind:withReuseIdentifier:addPlaceholder:)
    final func register(_ nib: UINib?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView?.register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let reusableView = nib?.instantiate(withOwner: nil, options: nil).first as? UICollectionReusableView else {
            return
        }
        reusableView.isHidden = true
        view.insertSubview(reusableView, at: 0) // so that the trait collections are updated
        placeholders["\(elementKind)-\(identifier)"] = reusableView
    }
    
    // MARK - 3D Touch
    
    var previewingContext: UIViewControllerPreviewing?
    
    
    func unregisterForPreviewing() {
        guard let context = previewingContext else {
            return
        }
        unregisterForPreviewing(withContext: context)
    }
    
    func registerForPreviewingIfAvailable() {
        wmf_ifForceTouchAvailable({
            self.unregisterForPreviewing()
            guard let collectionView = self.collectionView else {
                return
            }
            self.previewingContext = self.registerForPreviewing(with: self, sourceView: collectionView)
        }, unavailable: {
            self.unregisterForPreviewing()
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.registerForPreviewingIfAvailable()
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.colors.baseBackground
        collectionView?.backgroundColor = theme.colors.baseBackground
        collectionView?.indicatorStyle = theme.scrollIndicatorStyle
        collectionView?.reloadData()
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ColumnarCollectionViewController: UIViewControllerPreviewingDelegate {
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return nil
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    }
}

extension ColumnarCollectionViewController: WMFColumnarCollectionViewLayoutDelegate {
    open func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return index % 2 == 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 0)
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 0)
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 0)
    }
    
    func metrics(withBoundsSize size: CGSize, adjustedContentInsets: UIEdgeInsets) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, adjustedContentInsets: adjustedContentInsets, collapseSectionSpacing: false)
    }
}
