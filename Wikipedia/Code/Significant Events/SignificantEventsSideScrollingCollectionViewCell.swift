
import UIKit
import WMF

// Note: this is an amalgamation of both SideScrollingCollectionViewCell and OnThisDayCollectionViewCell
// We are purposely not repurposing those classes to limit risk
// However if experiment succeeds we should consider reworking SideScrollingCollectionViewCell to accept a generic side scrolling cell to work with, and have this class subclass from there instead.
// Also note, as experiment is EN-only, this class doesn't support RTL
class SignificantEventsSideScrollingCollectionViewCell: CollectionViewCell {
    
    static private let snippetCellIdentifier = "SignificantEventsSnippetCollectionViewCell"
    private var theme: Theme = Theme.standard
    
    private let descriptionLabel = UILabel()
    private let timestampLabel = UILabel()
    private let userInfoTextView = UITextView()
    //tonitodo: clean this button configuration up
    private lazy var thankButton: AlignedImageButton = {
        let button = AlignedImageButton()
        button.setImage(#imageLiteral(resourceName: "places-more"), for: .normal) //tonitodo: proper image
        //thankButton.isUserInteractionEnabled = false
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .left
        button.horizontalSpacing = 2
        button.verticalPadding = 4
        button.leftPadding = 10
        button.rightPadding = 10
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitle(WMFLocalizedString("significant-events-thank-title", value: "Thank", comment: "Button title that thanks users for their edit in significant events screen"), for: .normal)
       return button
    }()
    private lazy var viewChangesButton: AlignedImageButton = {
        let button = AlignedImageButton()
        button.setImage(#imageLiteral(resourceName: "places-more"), for: .normal) //tonitodo: proper image
        //thankButton.isUserInteractionEnabled = false
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .left
        button.horizontalSpacing = 2
        button.verticalPadding = 4
        button.leftPadding = 10
        button.rightPadding = 10
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitle(WMFLocalizedString("significant-events-view-changes", value: "View changes", comment: "Button title on a significant event cell that sends user to the revision history screen."), for: .normal)
       return button
    }()
    private lazy var viewDiscussionButton: AlignedImageButton = {
        let button = AlignedImageButton()
        button.setImage(#imageLiteral(resourceName: "places-more"), for: .normal) //tonitodo: proper image
        //thankButton.isUserInteractionEnabled = false
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .left
        button.horizontalSpacing = 2
        button.verticalPadding = 4
        button.leftPadding = 10
        button.rightPadding = 10
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitle(WMFLocalizedString("significant-events-view-discussion", value: "View discussion", comment: "Button title on a significant event cell that sends a user to the significant event's talk page topic."), for: .normal)
       return button
    }()
    
    let timelineView = TimelineView()
    
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
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(userInfoTextView)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(collectionView)
        timelineView.isOpaque = true
        timestampLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        userInfoTextView.isOpaque = true
        
        timelineView.decoration = .singleDot
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

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        layoutMarginsAdditions = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5)
        
        let layoutMargins = calculatedLayoutMargins
        
        let timelineTextSpacing = CGFloat(5)
        let timelineWidth = CGFloat(15)
        let x = layoutMargins.left + timelineWidth + timelineTextSpacing
        let widthToFit = size.width - layoutMargins.right - x
        
        if apply {
            timelineView.frame = CGRect(x: layoutMargins.left, y: 0, width: timelineWidth, height: size.height)
        }
        
        
        let timestampOrigin = CGPoint(x: x, y: layoutMargins.top)
        
        let timestampFrame = timestampLabel.wmf_preferredFrame(at: timestampOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let timestampDescriptionSpacing = CGFloat(6)
        
        let descriptionOrigin = CGPoint(x: x, y: timestampFrame.maxY + timestampDescriptionSpacing)
        
        let descriptionFrame = descriptionLabel.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let collectionViewOrigin = CGPoint(x: x, y: descriptionFrame.maxY)
        
        let collectionViewSpacing: CGFloat = 10
        var collectionViewHeight = prototypeCell.wmf_preferredHeight(at: collectionViewOrigin, maximumWidth: widthToFit, alignedBy: .forceLeftToRight, spacing: 2 * collectionViewSpacing, apply: false)

        if changeDetails.isEmpty {
            collectionViewHeight = 0
        }

        if (apply) {
            flowLayout?.itemSize = CGSize(width: 250, height: collectionViewHeight - 2 * collectionViewSpacing)
            flowLayout?.minimumInteritemSpacing = collectionViewSpacing
            flowLayout?.minimumLineSpacing = 15
            flowLayout?.sectionInset = UIEdgeInsets(top: collectionViewSpacing, left: 0, bottom: collectionViewSpacing, right: collectionViewSpacing)
            collectionView.frame = CGRect(x: 0, y: collectionViewOrigin.y, width: size.width, height: collectionViewHeight)
            collectionView.contentInset = UIEdgeInsets(top: 0, left: x - collectionViewSpacing, bottom: 0, right: 0)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        
        let collectionViewUserInfoLabelSpacing = CGFloat(0)
        
        let userInfoOrigin = CGPoint(x: x, y: descriptionFrame.maxY + collectionViewHeight + collectionViewUserInfoLabelSpacing)
        
        let userInfoFrame =
            userInfoTextView.wmf_preferredFrame(at: userInfoOrigin, maximumWidth: widthToFit, alignedBy: .forceLeftToRight, apply: apply)
        
        guard let largeEvent = largeEvent else {
            let finalHeight = userInfoFrame.maxY + layoutMargins.bottom
            return CGSize(width: size.width, height: finalHeight)
        }
        
        let userInfoButtonsSpacing = CGFloat(4)
        let buttonsSpacing = CGFloat(20)
        let mysteriousButtonXOriginOffsetNeeded = CGFloat(10)
        
        var finalHeight = userInfoFrame.maxY
        switch largeEvent.buttonsToDisplay {
        case .thankAndViewChanges:
            let thankOrigin = CGPoint(x: x + mysteriousButtonXOriginOffsetNeeded, y: userInfoFrame.maxY + userInfoButtonsSpacing)

            let thankFrame = thankButton.wmf_preferredFrame(at: thankOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            
            let viewChangesOrigin = CGPoint(x: thankFrame.maxX + buttonsSpacing, y: userInfoFrame.maxY + userInfoButtonsSpacing)
            let _ = viewChangesButton.wmf_preferredFrame(at: viewChangesOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            finalHeight = thankFrame.maxY
            thankButton.cornerRadius = thankFrame.height / 2
            viewChangesButton.cornerRadius = thankFrame.height / 2
        case .viewDiscussion:
            let viewDiscussionOrigin = CGPoint(x: x + mysteriousButtonXOriginOffsetNeeded, y: userInfoFrame.maxY + userInfoButtonsSpacing)
            let viewDiscussionFrame = viewDiscussionButton.wmf_preferredFrame(at: viewDiscussionOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            finalHeight = viewDiscussionFrame.maxY
            viewDiscussionButton.cornerRadius = viewDiscussionFrame.height / 2
        }
        
        let finalFinalHeight = finalHeight + layoutMargins.bottom
        return CGSize(width: size.width, height: finalFinalHeight)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = timestampLabel.convert(timestampLabel.bounds, to: timelineView).midY
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.accent
        timestampLabel.textColor = theme.colors.accent
        
        if let largeEvent = largeEvent {
            configure(with: largeEvent, theme: theme)
        }
        
        collectionView.backgroundColor = .clear
        collectionView.reloadData()
        
        if let largeEvent = largeEvent {
            switch largeEvent.buttonsToDisplay {
            case .thankAndViewChanges:
                thankButton.backgroundColor = theme.colors.midBackground
                viewChangesButton.backgroundColor = theme.colors.midBackground
            case .viewDiscussion:
                viewDiscussionButton.backgroundColor = theme.colors.midBackground
            }
        }
        
    }
    
    override func reset() {
        super.reset()
        
        largeEvent = nil
        changeDetails.removeAll()
        collectionView.reloadData()
        descriptionLabel.attributedText = nil
        userInfoTextView.attributedText = nil
        timestampLabel.text = nil
        thankButton.removeFromSuperview()
        viewChangesButton.removeFromSuperview()
        viewDiscussionButton.removeFromSuperview()
    }
    
    func resetContentOffset() {
        let x: CGFloat = -collectionView.contentInset.left
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    func configure(with largeEvent: LargeEventViewModel, theme: Theme) {

        self.largeEvent = largeEvent
    
        descriptionLabel.attributedText = largeEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        userInfoTextView.attributedText = largeEvent.userInfoForTraitCollection(traitCollection, theme: theme)
        timestampLabel.text = largeEvent.timestampForDisplay()
        timestampLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        

        switch largeEvent.buttonsToDisplay {
        case .thankAndViewChanges(let userId, let revisionId):
            contentView.addSubview(thankButton)
            contentView.addSubview(viewChangesButton)
            
            thankButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
            viewChangesButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
            
            thankButton.setTitleColor(theme.colors.link, for: .normal)
            viewChangesButton.setTitleColor(theme.colors.link, for: .normal)
            
            thankButton.setNeedsLayout()
            thankButton.layoutIfNeeded()
            viewChangesButton.setNeedsLayout()
            viewChangesButton.layoutIfNeeded()
        case .viewDiscussion(let sectionName):
            
            contentView.addSubview(viewDiscussionButton)
            
            viewDiscussionButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
            viewDiscussionButton.setTitleColor(theme.colors.link, for: .normal)
            
            viewDiscussionButton.setNeedsLayout()
            viewDiscussionButton.layoutIfNeeded()
        }
        
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
        case .reference(let reference):
            snippetCell.configure(snippet: reference.description, theme: theme)
            return snippetCell
        }
    }
}
