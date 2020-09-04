
import UIKit

// Note: this is an amalgamation of both SideScrollingCollectionViewCell and OnThisDayCollectionViewCell
// We are purposely not repurposing those classes to limit risk
// However if experiment succeeds we should consider reworking SideScrollingCollectionViewCell to accept a generic side scrolling cell to work with, and have this class subclass from there instead.
// Also note, as experiment is EN-only, this class doesn't support RTL
class SignificantEventsSideScrollingCollectionViewCell: CollectionViewCell {
    
    static private let snippetCellIdentifier = "SignificantEventsSnippetCollectionViewCell"
    private var theme: Theme = Theme.standard
    
    private let descriptionLabel = UILabel()
    private let timelineView = OnThisDayTimelineView()
    let timelineViewWidth:CGFloat = 66.0
    
    private var largeEvent: LargeEventViewModel? {
        didSet {
            if let largeEvent = largeEvent {
                changeDetails = largeEvent.changeDetailsForTraitCollection(traitCollection, theme: theme)
                collectionView.reloadData()
            }
        }
    }
    private var changeDetails: [LargeEventViewModel.ChangeDetail] = []
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let prototypeCell = SignificantEventsSnippetCollectionViewCell()
    
    override func setup() {
        descriptionLabel.isOpaque = true
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(collectionView)
        timelineView.isOpaque = true
        contentView.insertSubview(timelineView, belowSubview: collectionView)
        
        wmf_configureSubviewsForDynamicType()
        
        //Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        if let largeEventViewModel = LargeEventViewModel(forPrototypeText: "Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing Testing "),
           let snippetAttributedString = largeEventViewModel.firstSnippetFromPrototypeModel(traitCollection: traitCollection, theme: Theme.standard) { //standard theme since this cell is just for sizing
        
            prototypeCell.configure(snippet: snippetAttributedString, theme: theme)
        }
        
        prototypeCell.isHidden = true
        descriptionLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(SignificantEventsSnippetCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsSideScrollingCollectionViewCell.snippetCellIdentifier)
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        
        super.setup()
    }
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        if let largeEvent = largeEvent {
            configure(with: largeEvent, theme: theme)
        }
    }
    
    private let spacing: CGFloat = 0 //was 6

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let x = layoutMargins.left
        layoutMarginsAdditions = UIEdgeInsets(top: 0, left: timelineViewWidth, bottom: 0, right: 0)
        if apply {
            timelineView.frame = CGRect(x: x, y: 0, width: timelineViewWidth, height: size.height)
        }
        
        //return super.sizeThatFits(size, apply: apply)
        
        let layoutMargins = calculatedLayoutMargins
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthToFit = size.width - layoutMargins.left - layoutMargins.right
        
        origin.y += spacing
        origin.y += descriptionLabel.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: .forceLeftToRight, spacing: spacing, apply: apply)
        
        let collectionViewSpacing: CGFloat = 10
        var height = prototypeCell.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: .forceLeftToRight, spacing: 2 * collectionViewSpacing, apply: false)

        if changeDetails.isEmpty {
            height = 0
        }

        if (apply) {
            flowLayout?.itemSize = CGSize(width: 250, height: height - 2 * collectionViewSpacing)
            flowLayout?.minimumInteritemSpacing = collectionViewSpacing
            flowLayout?.minimumLineSpacing = 15
            flowLayout?.sectionInset = UIEdgeInsets(top: collectionViewSpacing, left: collectionViewSpacing, bottom: collectionViewSpacing, right: collectionViewSpacing)
            collectionView.frame = CGRect(x: 0, y: origin.y, width: size.width, height: height)
            collectionView.contentInset = UIEdgeInsets(top: 0, left: layoutMargins.left - collectionViewSpacing, bottom: 0, right: 0)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }

        origin.y += height
        origin.y += layoutMargins.bottom
        
        return CGSize(width: size.width, height: origin.y)
    }
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = descriptionLabel.convert(descriptionLabel.bounds, to: timelineView).minY
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.link
        
        if let largeEvent = largeEvent {
            configure(with: largeEvent, theme: theme)
        }
        
        collectionView.backgroundColor = .clear
        collectionView.reloadData()
    }
    
    override func reset() {
        super.reset()
        
        largeEvent = nil
        changeDetails.removeAll()
        collectionView.reloadData()
        descriptionLabel.attributedText = nil
    }
    
    func resetContentOffset() {
        let x: CGFloat = -collectionView.contentInset.left
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    func configure(with largeEvent: LargeEventViewModel, theme: Theme) {

        self.largeEvent = largeEvent
    
        descriptionLabel.attributedText = largeEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        
        resetContentOffset()
        setNeedsLayout()
    }
}

extension SignificantEventsSideScrollingCollectionViewCell: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return changeDetails.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  SignificantEventsSideScrollingCollectionViewCell.snippetCellIdentifier, for: indexPath)
        guard let snippetCell = cell as? SignificantEventsSnippetCollectionViewCell else {
            return cell
        }
        let changeDetailForCell = changeDetails[indexPath.item]
        switch changeDetailForCell {
        case .snippet(let snippet):
            snippetCell.configure(snippet: snippet.displayText, theme: theme)
            return snippetCell
        default:
            return cell
        }
    }
}
