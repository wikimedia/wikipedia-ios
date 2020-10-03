
import UIKit
import WMF

// Note: this is an amalgamation of both SideScrollingCollectionViewCell and OnThisDayCollectionViewCell
// We are purposely not repurposing those classes to limit risk
// However if experiment succeeds we should consider reworking SideScrollingCollectionViewCell to accept a generic side scrolling cell to work with, and have this class subclass from there instead.
// Also note, as experiment is EN-only, this class doesn't support RTL
class ArticleAsLivingDocLargeEventCollectionViewCell: CollectionViewCell {
    
    private var theme: Theme = Theme.standard
    
    private let descriptionLabel = UILabel()
    private let timestampLabel = UILabel()
    private let userInfoTextView = UITextView()
    //tonitodo: clean this button configuration up
    private lazy var thankButton: AlignedImageButton = {
        return actionButton(with: #imageLiteral(resourceName: "places-more"), text: WMFLocalizedString("aaald-events-thank-title", value: "Thank", comment: "Button title that thanks users for their edit in article as a living document screen"))
    }()
    private lazy var viewChangesButton: AlignedImageButton = {
        return actionButton(with: #imageLiteral(resourceName: "places-more"), text: WMFLocalizedString("aaald-view-changes", value: "View changes", comment: "Button title on a article as a living document cell that sends user to the revision history screen."))
    }()
    private lazy var viewDiscussionButton: AlignedImageButton = {
        return actionButton(with: #imageLiteral(resourceName: "places-more"), text: WMFLocalizedString("aaald-view-discussion", value: "View discussion", comment: "Button title on an article as a living document cell that sends a user to the event's talk page topic."))
    }()
    
    let timelineView = TimelineView()

    weak var delegate: ArticleAsLivingDocHorizontallyScrollingCellDelegate?
    weak var historyDelegate: EditHistoryShowing?
    
    private var largeEvent: ArticleAsLivingDocViewModel.Event.Large? {
        didSet {
            calculateChangeDetails()
        }
    }
    private var changeDetails: [ArticleAsLivingDocViewModel.Event.Large.ChangeDetail] = []
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private let snippetPrototypeCell = ArticleAsLivingDocSnippetCollectionViewCell()
    private let referencePrototypeCell = ArticleAsLivingDocReferenceCollectionViewCell()
    
    private var collectionViewHeight: CGFloat = 0
    private var cachedItemHeights: [String: CGFloat] = [:]
    
    private let maximumSideScrollingCellWidth = CGFloat(250)
    
    override func setup() {
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(userInfoTextView)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(collectionView)
        timelineView.isOpaque = true
        timestampLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        userInfoTextView.isOpaque = true

        userInfoTextView.delegate = self
        
        timelineView.decoration = .singleDot
        contentView.insertSubview(timelineView, belowSubview: collectionView)
        
        wmf_configureSubviewsForDynamicType()
        
        snippetPrototypeCell.isHidden = true
        referencePrototypeCell.isHidden = true
        
        descriptionLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(ArticleAsLivingDocSnippetCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocSnippetCollectionViewCell.identifier)
        collectionView.register(ArticleAsLivingDocReferenceCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocReferenceCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.clipsToBounds = false
        
        super.setup()
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
        
        let descriptionCollectionViewSpacing = CGFloat(5)
        
        let collectionViewOrigin = CGPoint(x: x, y: descriptionFrame.maxY + descriptionCollectionViewSpacing)
        
        collectionViewHeight = largestItemHeightForWidth(maximumSideScrollingCellWidth)
        let collectionViewItemSpacing = CGFloat(10)

        if (apply) {
            flowLayout?.minimumInteritemSpacing = collectionViewItemSpacing
            flowLayout?.minimumLineSpacing = 15
            flowLayout?.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            collectionView.frame = CGRect(x: 0, y: collectionViewOrigin.y, width: size.width, height: collectionViewHeight)
            collectionView.contentInset = UIEdgeInsets(top: 0, left: x, bottom: 0, right: 0)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        
        let collectionViewUserInfoLabelSpacing = CGFloat(5)
        
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
    
    func itemHeightCacheKeyForWidth(_ width: CGFloat, index: Int) -> String {
        return "\(index)-\(width)"
    }
    
    private func largestItemHeightForWidth(_ width: CGFloat) -> CGFloat {
        var largestItemHeight: CGFloat = 0
        for (i, change) in changeDetails.enumerated() {
            let key = itemHeightCacheKeyForWidth(width, index: i)
            let height: CGFloat
            if let cachedHeight = cachedItemHeights[key] {
                height = cachedHeight
            } else {
                switch change {
                case .snippet:
                    snippetPrototypeCell.configure(change: change, theme: theme, delegate: self)
                    height = snippetPrototypeCell.wmf_preferredHeight(at: .zero, maximumWidth: width, alignedBy: .forceLeftToRight, spacing: 0, apply: false)
                    cachedItemHeights[key] = height
                case .reference:
                    referencePrototypeCell.configure(change: change, theme: theme, delegate: self)
                    height = referencePrototypeCell.wmf_preferredHeight(at: .zero, maximumWidth: width, alignedBy: .forceLeftToRight, spacing: 0, apply: false)
                    cachedItemHeights[key] = height
                }
            }
            
            if largestItemHeight < height {
                largestItemHeight = height
            }
        }
        
        return largestItemHeight
    }
    
    private func actionButton(with image: UIImage, text: String) -> AlignedImageButton {
        let button = AlignedImageButton()
        button.setImage(image, for: .normal) //tonitodo: proper image
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .left
        button.horizontalSpacing = 2
        button.verticalPadding = 4
        button.leftPadding = 10
        button.rightPadding = 10
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitle(text, for: .normal)
       return button
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = timestampLabel.convert(timestampLabel.bounds, to: timelineView).midY
    }
    
    private func calculateChangeDetails() {
        if let largeEvent = largeEvent {
            changeDetails = largeEvent.changeDetailsForTraitCollection(traitCollection, theme: theme)
            collectionView.reloadData()
        }
    }
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        calculateChangeDetails()
        
        if let largeEvent = largeEvent {
            configure(with: largeEvent, theme: theme)
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.accent
        timestampLabel.textColor = theme.colors.accent
        userInfoTextView.backgroundColor = theme.colors.paperBackground
        descriptionLabel.textColor = theme.colors.primaryText
        
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
        cachedItemHeights.removeAll()
        collectionViewHeight = 0
    }
    
    func resetContentOffset() {
        let x: CGFloat = -collectionView.contentInset.left
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    func configure(with largeEvent: ArticleAsLivingDocViewModel.Event.Large, theme: Theme) {

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

            viewChangesButton.removeTarget(nil, action: nil, for: .allEvents)
            viewChangesButton.addTarget(self, action: #selector(viewChangesTapped), for: .touchUpInside)
        case .viewDiscussion(let sectionName):
            
            contentView.addSubview(viewDiscussionButton)
            
            viewDiscussionButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
            viewDiscussionButton.setTitleColor(theme.colors.link, for: .normal)
            
            viewDiscussionButton.setNeedsLayout()
            viewDiscussionButton.layoutIfNeeded()
        }
        
        apply(theme: theme)
        resetContentOffset()
        setNeedsLayout()
    }

    @objc private func viewChangesTapped() {
        guard let revisionID = largeEvent?.revId else {
            return
        }
        historyDelegate?.goToHistory(scrolledTo: Int(revisionID))
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return changeDetails.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let changeDetailForCell = changeDetails[indexPath.item]
        
        switch changeDetailForCell {
        case .snippet:
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  ArticleAsLivingDocSnippetCollectionViewCell.identifier, for: indexPath)
            
            guard let snippetCell = cell as? ArticleAsLivingDocSnippetCollectionViewCell else {
                return cell
            }
            
            snippetCell.configure(change: changeDetailForCell, theme: theme, delegate: self)
            return snippetCell
            
        case .reference:
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  ArticleAsLivingDocReferenceCollectionViewCell.identifier, for: indexPath)
            
            guard let referenceCell = cell as? ArticleAsLivingDocReferenceCollectionViewCell else {
                return cell
            }
            
            referenceCell.configure(change: changeDetailForCell, theme: theme, delegate: self)
            return referenceCell
        }
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let changeDetail = changeDetails[indexPath.item]
        let cacheKey = itemHeightCacheKeyForWidth(maximumSideScrollingCellWidth, index: indexPath.item)
        if let height = cachedItemHeights[cacheKey] {
            return CGSize(width: maximumSideScrollingCellWidth, height: height)
        }
        
        switch changeDetail {
        case .snippet:
            snippetPrototypeCell.configure(change: changeDetail, theme: theme, delegate: self)
            return snippetPrototypeCell.sizeThatFits(CGSize(width: maximumSideScrollingCellWidth, height: collectionViewHeight), apply: false)
        case .reference:
            referencePrototypeCell.configure(change: changeDetail, theme: theme, delegate: self)
            return referencePrototypeCell.sizeThatFits(CGSize(width: maximumSideScrollingCellWidth, height: collectionViewHeight), apply: false)
        }
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCellDelegate {
    func tappedLink(_ url: URL, cell: ArticleAsLivingDocHorizontallyScrollingCell?, sourceView: UIView, sourceRect: CGRect?) {
        delegate?.tappedLink(url, cell: cell, sourceView: sourceView, sourceRect: sourceRect)
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(url, cell: nil, sourceView: textView, sourceRect: textView.frame(of: characterRange))
        return false
    }
}
