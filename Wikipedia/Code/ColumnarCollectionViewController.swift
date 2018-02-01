import UIKit

@objc(WMFColumnarCollectionViewController)
class ColumnarCollectionViewController: ViewController {
    lazy var layout: WMFColumnarCollectionViewLayout = {
        return WMFColumnarCollectionViewLayout()
    }()
    
    @objc lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        scrollView = cv
        return cv
    }()

    fileprivate var placeholders: [String:UICollectionReusableView] = [:]

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        collectionView.alwaysBounceVertical = true
        extendedLayoutIncludesOpaqueBars = true
    }

    @objc func contentSizeCategoryDidChange(_ notification: Notification?) {
        collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForPreviewingIfAvailable()
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            for selectedIndexPath in selectedIndexPaths {
                collectionView.deselectItem(at: selectedIndexPath, animated: animated)
            }
        }
        for cell in collectionView.visibleCells {
            guard let cellWithSubItems = cell as? SubCellProtocol else {
                continue
            }
            cellWithSubItems.deselectSelectedSubItems(animated: animated)
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
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
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
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        guard let cell = nib?.instantiate(withOwner: nil, options: nil).first as? UICollectionViewCell else {
            return
        }
        cell.isHidden = true
        view.insertSubview(cell, at: 0) // so that the trait collections are updated
        placeholders[identifier] = cell
    }
    
    @objc(registerViewClass:forSupplementaryViewOfKind:withReuseIdentifier:addPlaceholder:)
    final func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
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
        collectionView.register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
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
            self.previewingContext = self.registerForPreviewing(with: self, sourceView: collectionView)
        }, unavailable: {
            self.unregisterForPreviewing()
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.registerForPreviewingIfAvailable()
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            contentSizeCategoryDidChange(nil)
        }
    }
    
    // MARK: - Scroll
    
    internal override func scrollToTop() {
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: 0 - collectionView.contentInset.top), animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let hintPresenter = self as? ReadingListHintPresenter else {
            return
        }
        hintPresenter.readingListHintController?.scrollViewWillBeginDragging()
    }
    
    // MARK: - Themeable
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        collectionView.backgroundColor = theme.colors.baseBackground
        collectionView.indicatorStyle = theme.scrollIndicatorStyle
        collectionView.reloadData()
    }
}

extension ColumnarCollectionViewController: UICollectionViewDataSource {
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
    }
}

extension ColumnarCollectionViewController: UICollectionViewDelegate {

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
    
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth)
    }
}

// MARK: - WMFArticlePreviewingActionsDelegate
extension ColumnarCollectionViewController: WMFArticlePreviewingActionsDelegate {
    func saveArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, didSave: Bool, articleURL: URL) {
        guard let hintPresenter = self as? ReadingListHintPresenter else {
            return
        }
        hintPresenter.readingListHintController?.didSave(didSave, articleURL: articleURL, theme: theme)
        
    }
    
    func readMoreArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        wmf_push(articleController, animated: true)
    }
    
    func shareArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, shareActivityController: UIActivityViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        present(shareActivityController, animated: true, completion: nil)
    }
    
    func viewOnMapArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        let placesURL = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: articleController.articleURL)
        UIApplication.shared.open(placesURL, options: [:], completionHandler: nil)
    }
}
