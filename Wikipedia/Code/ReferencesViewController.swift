import UIKit
import WMF.Swift

protocol ReferencesViewControllerDelegate: AnyObject {
    func referencesViewControllerUserDidTapClose(_ referencesViewController: ReferencesViewController)
    func referencesViewController(_ referencesViewController: ReferencesViewController, userDidTapLinkWithURL url: URL)
}

class ReferencesViewController: ColumnarCollectionViewController {
    private static let cellReuseIdentifier = "org.wikimedia.references"
    private let references: References
    private weak var delegate: ReferencesViewControllerDelegate?
    
    required init(references: References, theme: Theme, delegate: ReferencesViewControllerDelegate?) {
        self.references = references
        self.delegate = delegate
        super.init(theme: theme)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsSelection = false
        
        title = WMFLocalizedString("references-title", value: "References", comment: "Title for the view that shows page references.")
        
        layoutManager.register(HTMLCollectionViewCell.self, forCellWithReuseIdentifier: ReferencesViewController.cellReuseIdentifier, addPlaceholder: true)
        
        let xButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonPressed))
        navigationItem.leftBarButtonItem = xButton
        apply(theme: self.theme)
    }
    
    @objc func closeButtonPressed() {
        delegate?.referencesViewControllerUserDidTapClose(self)
    }
    
    // MARK: - Data Source
    
    private func referenceList(at section: Int) -> ReferenceList? {
        guard references.referenceLists.count > section else {
            return nil
        }
        return references.referenceLists[section]
    }
    
    private func referenceKey(at indexPath: IndexPath) -> String? {
        guard let referenceList = referenceList(at: indexPath.section) else {
            return nil
        }
        guard referenceList.order.count > indexPath.item else {
            return nil
        }
        return referenceList.order[indexPath.item]
    }
    
    private func reference(at indexPath: IndexPath) -> Reference? {
        guard let referenceKey = referenceKey(at: indexPath) else {
            return nil
        }
        return references.referencesByID[referenceKey]
    }

    // MARK: - Collection View Data Source

    private func configure(cell: HTMLCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.apply(theme: theme)
        cell.layoutMargins = layout.itemLayoutMargins
        cell.html = reference(at: indexPath)?.content.html
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: ReferencesViewController.cellReuseIdentifier, for: indexPath)
        guard let cell = maybeCell as? HTMLCollectionViewCell else {
            return maybeCell
        }
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        cell.delegate = self
        return cell
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return references.referenceLists.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard references.referenceLists.count > section else {
            return 0
        }
        return references.referenceLists[section].order.count
    }
    
    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }
    
    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        header.style = .history
        header.title = referenceList(at: sectionIndex)?.heading.html.removingHTML
        header.apply(theme: theme)
        header.layoutMargins = layout.itemLayoutMargins
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let reuseIdentifier = ReferencesViewController.cellReuseIdentifier
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 0)
        guard
            let referenceKey = referenceKey(at: indexPath),
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
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: ReferencesViewController.cellReuseIdentifier, columnWidth: columnWidth, userInfo: referenceKey)
        return estimate
    }
    
    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
    }
}


extension ReferencesViewController: HTMLCollectionViewCellDelegate {
    func collectionViewCell(_ HTMLCollectionViewCell: HTMLCollectionViewCell, didTapLinkWith url: URL) {
        delegate?.referencesViewController(self, userDidTapLinkWithURL: url)
    }
}
