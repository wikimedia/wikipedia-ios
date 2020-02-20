protocol ReferenceBackLinksViewControllerDelegate: class {
    func referenceBackLinksViewControllerUserDidTapClose(_ referenceBackLinksViewController: ReferenceBackLinksViewController)
    func referenceBackLinksViewControllerUserDidInteractWithHref(_ href: String, referenceBackLinksViewController: ReferenceBackLinksViewController)
}

class ReferenceBackLinksViewController: ColumnarCollectionViewController {
    private static let cellReuseIdentifier = "org.wikimedia.references"
    weak var delegate: ReferenceBackLinksViewControllerDelegate?
    
    let backLinks: [ReferenceBackLink]
    init(backLinks: [ReferenceBackLink], delegate: ReferenceBackLinksViewControllerDelegate?, theme: Theme) {
        self.backLinks = backLinks
        self.delegate = delegate
        super.init(theme: theme)
        navigationMode = .forceBar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutManager.register(HTMLCollectionViewCell.self, forCellWithReuseIdentifier: ReferenceBackLinksViewController.cellReuseIdentifier, addPlaceholder: true)
        
        let xButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonPressed))
        navigationItem.leftBarButtonItem = xButton
        apply(theme: self.theme)
    }
    
    @objc func closeButtonPressed() {
        delegate?.referenceBackLinksViewControllerUserDidTapClose(self)
    }
    
    func getBackLink(at indexPath: IndexPath) -> ReferenceBackLink? {
        guard indexPath.item < backLinks.count else {
            return nil
        }
        return backLinks[indexPath.item]
    }
    
    // MARK: - Collection View Data Source
    
    private func configure(cell: HTMLCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.apply(theme: theme)
        cell.layoutMargins = layout.itemLayoutMargins
        guard let backLink = getBackLink(at: indexPath) else {
            cell.html = nil
            return
        }
        print(backLink.html)
        cell.html = backLink.html
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: ReferenceBackLinksViewController.cellReuseIdentifier, for: indexPath)
        guard let cell = maybeCell as? HTMLCollectionViewCell else {
            return maybeCell
        }
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        cell.delegate = self
        return cell
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backLinks.count
    }
    
    //     override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
    //        return .sections
    //    }
    
    //     override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
    //        header.style = .history
    //        header.title = referenceList(at: sectionIndex)?.heading.html.removingHTML
    //        header.apply(theme: theme)
    //        header.layoutMargins = layout.itemLayoutMargins
    //    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let reuseIdentifier = ReferenceBackLinksViewController.cellReuseIdentifier
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 0)
        guard
            let referenceKey = getBackLink(at: indexPath)?.id,
            let placeholder = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? HTMLCollectionViewCell
            else {
                return estimate
        }
        if let cached = layoutCache.cachedHeightForCellWithIdentifier(reuseIdentifier, columnWidth: columnWidth, userInfo: referenceKey) {
            estimate.height = cached
            estimate.precalculated = true
            return estimate
        }
        configure(cell: placeholder, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: reuseIdentifier, columnWidth: columnWidth, userInfo: referenceKey)
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: Theme
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        collectionView.backgroundColor = .clear
        view.backgroundColor = theme.colors.overlayBackground
    }
}

extension ReferenceBackLinksViewController: HTMLCollectionViewCellDelegate {
    func collectionViewCell(_ cell: HTMLCollectionViewCell, didTapLinkWith url: URL) {
        delegate?.referenceBackLinksViewControllerUserDidInteractWithHref(url.absoluteString, referenceBackLinksViewController: self)
    }
}
