
import UIKit
import WMF

// Note: this is an amalgamation of both SideScrollingCollectionViewCell and OnThisDayCollectionViewCell
// We are purposely not repurposing those classes to limit risk
// However if experiment succeeds we should consider reworking SideScrollingCollectionViewCell to accept a generic side scrolling cell to work with, and have this class subclass from there instead.
// Also note, as experiment is EN-only, this class doesn't support RTL
class ArticleAsLivingDocLargeEventCollectionViewCell: CollectionViewCell {
    
    private var theme: Theme?
    
    private let descriptionLabel = UILabel()
    private let timestampLabel = UILabel()
    private let userInfoTextView = UITextView()
    private lazy var thankButton: AlignedImageButton = {
        let image = UIImage(named: "thank-unfilled")
        return actionButton(with: image, text: WMFLocalizedString("aaald-events-thank-title", value: "Thank", comment: "Button title that thanks users for their edit in article as a living document screen"))
    }()
    private lazy var viewChangesButton: AlignedImageButton = {
        let image = UIImage(named: "document")
        return actionButton(with: image, text: WMFLocalizedString("aaald-view-changes", value: "View changes", comment: "Button title on a article as a living document cell that sends user to the revision history screen."))
    }()
    private lazy var viewDiscussionButton: AlignedImageButton = {
        let image = UIImage(named: "document")
        return actionButton(with: image, text: WMFLocalizedString("aaald-view-discussion", value: "View discussion", comment: "Button title on an article as a living document cell that sends a user to the event's talk page topic."))
    }()
    
    let timelineView = TimelineView()

    weak var delegate: ArticleAsLivingDocHorizontallyScrollingCellDelegate?
    weak var articleDelegate: ArticleDetailsShowing?
    
    private var largeEvent: ArticleAsLivingDocViewModel.Event.Large?
    private var changeDetails: [ArticleAsLivingDocViewModel.Event.Large.ChangeDetail] = []
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private var collectionViewHeight: CGFloat = 0

    private var isLoggedIn: Bool {
        return MWKDataStore.shared().authenticationManager.isLoggedIn
    }
    
    override func setup() {
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(userInfoTextView)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(collectionView)

        userInfoTextView.delegate = self
        userInfoTextView.isEditable = false
        
        timelineView.decoration = .singleDot
        contentView.insertSubview(timelineView, belowSubview: collectionView)
        
        wmf_configureSubviewsForDynamicType()
        
        descriptionLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(ArticleAsLivingDocSnippetCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocSnippetCollectionViewCell.identifier)
        collectionView.register(ArticleAsLivingDocReferenceCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocReferenceCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        
        super.setup()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        if (traitCollection.horizontalSizeClass == .compact) {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: -5, bottom: 20, right: 0)
        } else {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        }
        
        let layoutMargins = calculatedLayoutMargins
        
        let timelineTextSpacing: CGFloat = 7
        let timelineWidth: CGFloat = 15
        let x = layoutMargins.left + timelineWidth + timelineTextSpacing
        let widthToFit = size.width - layoutMargins.right - x
        
        if apply {
            timelineView.frame = CGRect(x: layoutMargins.left, y: 0, width: timelineWidth, height: size.height)
        }

        let timestampOrigin = CGPoint(x: x, y: layoutMargins.top)
        let timestampFrame = timestampLabel.wmf_preferredFrame(at: timestampOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)

        let timestampDescriptionSpacing: CGFloat = 8
        
        let descriptionOrigin = CGPoint(x: x, y: timestampFrame.maxY + timestampDescriptionSpacing)
        let descriptionFrame = descriptionLabel.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let descriptionCollectionViewSpacing: CGFloat = 10
        
        let collectionViewOrigin = CGPoint(x: x, y: descriptionFrame.maxY + descriptionCollectionViewSpacing)
        
        if let theme = theme,
           let largestChangeDetailHeight = largeEvent?.calculateSideScrollingCollectionViewHeightForTraitCollection(traitCollection, theme: theme) {
            collectionViewHeight = largestChangeDetailHeight
        } else {
            collectionViewHeight = 0
        }
        let collectionViewItemSpacing: CGFloat = 10

        if (apply) {
            flowLayout?.minimumInteritemSpacing = collectionViewItemSpacing
            flowLayout?.minimumLineSpacing = 15
            flowLayout?.sectionInset = UIEdgeInsets(top: 0, left: x, bottom: 0, right: layoutMargins.right)
            collectionView.frame = CGRect(x: 0, y: collectionViewOrigin.y, width: size.width, height: collectionViewHeight)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        
        let collectionViewUserInfoLabelSpacing: CGFloat = 0
        
        let userInfoOrigin = CGPoint(x: x, y: descriptionFrame.maxY + collectionViewHeight + descriptionCollectionViewSpacing + collectionViewUserInfoLabelSpacing)
        let userInfoFrame =
            userInfoTextView.wmf_preferredFrame(at: userInfoOrigin, maximumWidth: widthToFit, alignedBy: .forceLeftToRight, apply: apply)
        
        guard let largeEvent = largeEvent else {
            let finalHeight = userInfoFrame.maxY + layoutMargins.bottom
            return CGSize(width: size.width, height: finalHeight)
        }
        
        let userInfoButtonsSpacing: CGFloat = 6
        let buttonsSpacing: CGFloat = 20
        var finalHeight = userInfoFrame.maxY
        switch largeEvent.buttonsToDisplay {
        case .thankAndViewChanges:
            
            //Note: AlignedImageButton overrides wmf_preferredFrame and adjusts the frame origin x value by the leftPadding amount. I'm not sure why it does this but to prevent risk with tinkering on a widespread view we are resetting that offset here.
            let thankXOffset = thankButton.leftPadding
            let thankOrigin = CGPoint(x: x + thankXOffset, y: userInfoFrame.maxY + userInfoButtonsSpacing)

            let thankFrame = thankButton.wmf_preferredFrame(at: thankOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            
            let viewChangesOrigin = CGPoint(x: thankFrame.maxX + buttonsSpacing, y: userInfoFrame.maxY + userInfoButtonsSpacing)
            viewChangesButton.wmf_preferredFrame(at: viewChangesOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            finalHeight = thankFrame.maxY
            thankButton.cornerRadius = thankFrame.height / 2
            viewChangesButton.cornerRadius = thankFrame.height / 2
        case .viewDiscussion:
            
            //Note: See above note on thankXOffset for reasons for this offset.
            let viewDiscussionXOffset = viewDiscussionButton.leftPadding
            let viewDiscussionOrigin = CGPoint(x: x + viewDiscussionXOffset, y: userInfoFrame.maxY + userInfoButtonsSpacing)
            let viewDiscussionFrame = viewDiscussionButton.wmf_preferredFrame(at: viewDiscussionOrigin, maximumWidth: widthToFit, horizontalAlignment: .left, apply: apply)
            finalHeight = viewDiscussionFrame.maxY
            viewDiscussionButton.cornerRadius = viewDiscussionFrame.height / 2
        }
        
        let finalFinalHeight = finalHeight + layoutMargins.bottom
        return CGSize(width: size.width, height: finalFinalHeight)
    }
    
    private func actionButton(with image: UIImage?, text: String) -> AlignedImageButton {
        let button = AlignedImageButton()
        button.setImage(image, for: .normal)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .left
        button.horizontalSpacing = 6
        button.verticalPadding = 2
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
    
    func setAttributedStringViews() {
        
        guard let largeEvent = largeEvent,
              let theme = theme else {
            return
        }
        
        descriptionLabel.attributedText = largeEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        userInfoTextView.attributedText = largeEvent.userInfoForTraitCollection(traitCollection, theme: theme)
        
        changeDetails = largeEvent.changeDetailsForTraitCollection(traitCollection, theme: theme)
        collectionView.reloadData()
    }
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        
        if let theme = theme {
            largeEvent?.resetAttributedStringsIfNeededWithTraitCollection(traitCollection, theme: theme)
        }
        
        setAttributedStringViews()
        
        timestampLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        thankButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        viewChangesButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        viewDiscussionButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        
        largeEvent?.resetAttributedStringsIfNeededWithTraitCollection(traitCollection, theme: theme)
        
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.accent
        timestampLabel.textColor = theme.colors.accent
        userInfoTextView.backgroundColor = theme.colors.paperBackground
        descriptionLabel.textColor = theme.colors.primaryText

        if let largeEvent = largeEvent {
            switch largeEvent.buttonsToDisplay {
            case .thankAndViewChanges:
                thankButton.backgroundColor = largeEvent.wereThanksSent ? theme.colors.cardButtonSelectedBackground : theme.colors.cardButtonBackground
                thankButton.setTitleColor(!isLoggedIn ? theme.colors.disabledLink : theme.colors.link, for: .normal)
                thankButton.tintColor = (!isLoggedIn ? theme.colors.disabledLink : theme.colors.link)

                viewChangesButton.backgroundColor = theme.colors.cardButtonBackground
                viewChangesButton.setTitleColor(theme.colors.link, for: .normal)
            case .viewDiscussion:
                viewDiscussionButton.backgroundColor = theme.colors.cardButtonBackground
                viewDiscussionButton.setTitleColor(theme.colors.link, for: .normal)
            }
        }

        collectionView.backgroundColor = .clear
        
        setAttributedStringViews()
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
        collectionViewHeight = 0
    }
    
    func resetContentOffset() {
        let x: CGFloat = -collectionView.contentInset.left
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    func configure(with largeEvent: ArticleAsLivingDocViewModel.Event.Large, theme: Theme, extendTimelineAboveDot: Bool? = nil) {

        self.largeEvent = largeEvent
        self.largeEvent?.resetAttributedStringsIfNeededWithTraitCollection(traitCollection, theme: theme)
        apply(theme: theme)
    
        timestampLabel.text = largeEvent.timestampForDisplay()
        
        if let extendTimelineAboveDot = extendTimelineAboveDot {
            timelineView.extendTimelineAboveDot = extendTimelineAboveDot
        }

        switch largeEvent.buttonsToDisplay {
        case .thankAndViewChanges:
            contentView.addSubview(thankButton)
            contentView.addSubview(viewChangesButton)
            
            thankButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
            viewChangesButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)

            if largeEvent.wereThanksSent {
                thankButton.setImage(UIImage(named: "thank"), for: .normal)
                thankButton.setTitle(WMFLocalizedString("aaald-events-thanked-title", value: "Thanked", comment: "Button title after a user thanks an editor - past tense of 'thank'"), for: .normal)
            } else {
                thankButton.setImage(UIImage(named: "thank-unfilled"), for: .normal)
                thankButton.setTitle(WMFLocalizedString("aaald-events-thank-title", value: "Thank", comment: "Button title that thanks users for their edit in article as a living document screen"), for: .normal)
            }

            thankButton.setNeedsLayout()
            thankButton.layoutIfNeeded()
            viewChangesButton.setNeedsLayout()
            viewChangesButton.layoutIfNeeded()

            thankButton.removeTarget(nil, action: nil, for: .allEvents)
            thankButton.addTarget(self, action: #selector(thankButtonTapped), for: .touchUpInside)

            viewChangesButton.removeTarget(nil, action: nil, for: .allEvents)
            viewChangesButton.addTarget(self, action: #selector(viewChangesTapped), for: .touchUpInside)
        case .viewDiscussion:
            
            contentView.addSubview(viewDiscussionButton)

            viewDiscussionButton.setNeedsLayout()
            viewDiscussionButton.layoutIfNeeded()

            viewDiscussionButton.removeTarget(nil, action: nil, for: .allEvents)
            viewDiscussionButton.addTarget(self, action: #selector(viewDiscussionTapped), for: .touchUpInside)
        }
        
        setAttributedStringViews()
        resetContentOffset()
        setNeedsLayout()
    }

    @objc private func thankButtonTapped() {
        guard let largeEvent = largeEvent else {
            return
        }
        let isUserAnonymous = (largeEvent.userType == .anonymous)
        let eventTypes = ArticleAsLivingDocFunnel.EventType.eventTypesFromLargeEvent(largeEvent)
        let position = largeEvent.loggingPosition
        let livingDocLoggingValues = ArticleAsLivingDocLoggingValues(position: position, eventTypes: eventTypes)
        articleDelegate?.thankButtonTapped(for: Int(largeEvent.revId), isUserAnonymous: isUserAnonymous, livingDocLoggingValues: livingDocLoggingValues)
    }

    @objc private func viewChangesTapped() {
        
        guard let largeEvent = largeEvent else {
            return
        }
        
        let loggingPosition = largeEvent.loggingPosition
        let eventTypes = ArticleAsLivingDocFunnel.EventType.eventTypesFromLargeEvent(largeEvent)
        ArticleAsLivingDocFunnel.shared.logModalViewChangesButtonTapped(position: loggingPosition, types: eventTypes)
        
        articleDelegate?.goToDiff(revisionId: largeEvent.revId, parentId: largeEvent.parentId, diffType: .single)

    }

    @objc private func viewDiscussionTapped() {
        
        if let loggingPosition = largeEvent?.loggingPosition {
            ArticleAsLivingDocFunnel.shared.logModalViewDiscussionButtonTapped(position: loggingPosition)
        }
        
        guard let largeEvent = largeEvent else {
            return
        }
        
        switch largeEvent.buttonsToDisplay {
        case .viewDiscussion(let sectionName):
            articleDelegate?.showTalkPageWithSectionName(sectionName)
        default:
            assertionFailure("Unexpected button type")
            articleDelegate?.showTalkPageWithSectionName(nil)
        }
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
        guard indexPath.item < changeDetails.count,
              let theme = theme else {
            return UICollectionViewCell()
        }

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
        
        return CGSize(width: ArticleAsLivingDocViewModel.Event.Large.sideScrollingCellWidth, height: collectionViewHeight - ArticleAsLivingDocViewModel.Event.Large.additionalPointsForShadow)
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCellDelegate {
    func tappedLink(_ url: URL) {
        
        guard let largeEvent = largeEvent else {
            return
        }
        
        let loggingPosition = largeEvent.loggingPosition
        let eventTypes = ArticleAsLivingDocFunnel.EventType.eventTypesFromLargeEvent(largeEvent)
        ArticleAsLivingDocFunnel.shared.logModalSideScrollingCellLinkTapped(position: loggingPosition, types: eventTypes)
        
        delegate?.tappedLink(url)
    }
}

extension ArticleAsLivingDocLargeEventCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        guard let largeEvent = largeEvent else {
            return false
        }
        
        //note for now only userInfoTextView's delegate is self, and the only link possible in that text view is the username, so it's safe to log this
        let loggingPosition = largeEvent.loggingPosition
        let eventTypes = ArticleAsLivingDocFunnel.EventType.eventTypesFromLargeEvent(largeEvent)
        ArticleAsLivingDocFunnel.shared.logModalEditorNameTapped(position: loggingPosition, types: eventTypes)
        
        delegate?.tappedLink(url)
        return false
    }
}
