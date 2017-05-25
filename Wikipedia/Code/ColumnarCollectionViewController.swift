import UIKit

@objc(WMFColumnarCollectionViewController)
class ColumnarCollectionViewController: UICollectionViewController {
    let layout: WMFColumnarCollectionViewLayout = WMFColumnarCollectionViewLayout()

    init() {
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .wmf_settingsBackground
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForPreviewingIfAvailable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForPreviewing()
    }
    
    // MARK - Cell & View Registration
    
    @objc(registerCellClass:forCellWithReuseIdentifier:)
    final func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        collectionView?.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    @objc(registerNib:forCellWithReuseIdentifier:)
    final func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        collectionView?.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    @objc(registerViewClass:forSupplementaryViewOfKind:withReuseIdentifier:)
    final func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        collectionView?.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    @objc(registerNib:forSupplementaryViewOfKind:withReuseIdentifier:)
    final func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        collectionView?.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
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
}


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
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 0)
    }
    
    func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics(boundsSize: size, firstColumnRatio: 1, secondColumnRatio: 1)
    }
}
