import WMFComponents
import WMF

final class TalkPageCellTopicView: SetupView {
    
    enum DisplayMode {
        case subscribeMetadataReplies // showing subscribe, metadata, & replies
        case metadataReplies // hiding subscribe, showing metadata, & replies
        case none // hiding subscribe, metadata, & replies
    }

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var disclosureHorizontalStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var subscribeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = WMFFont.for(.mediumSubheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.black, for: .normal)
        button.setImage(UIImage(systemName: "bell"), for: .normal)
        button.tintColor = .black

        button.setContentCompressionResistancePriority(.required, for: .vertical)

        return button
    }()

    lazy var disclosureButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .black
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    lazy var disclosureCenterSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 99999)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        return view
    }()

    lazy var topicTitleTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.accessibilityTraits = [.header]
        textView.delegate = self
        return textView
    }()

    lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = WMFFont.for(.callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var topicCommentTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.delegate = self
        return textView
    }()

    lazy var metadataHorizontalStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var metadataSpacer: HorizontalSpacerView = {
        let spacer = HorizontalSpacerView.spacerWith(space: 10)
        return spacer
    }()

    lazy var activeUsersStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
        return stackView
    }()

    lazy var activeUsersImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()

    lazy var activeUsersLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = WMFFont.for(.callout)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var repliesStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        return stackView
    }()

    lazy var repliesImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bubble.left"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()

    lazy var repliesCountLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = WMFFont.for(.callout)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var variableMetadataCenterSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 99999)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        return view
    }()
    
    override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            updateSemanticContentAttribute(semanticContentAttribute)
        }
    }
    
    private var displayMode: DisplayMode = .subscribeMetadataReplies
    
    private weak var viewModel: TalkPageCellViewModel?
    weak var linkDelegate: TalkPageTextViewLinkHandling?

    // MARK: - Lifecycle

    override func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(disclosureHorizontalStack)

        disclosureHorizontalStack.addArrangedSubview(subscribeButton)
        disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
        disclosureHorizontalStack.addArrangedSubview(disclosureButton)

        stackView.addArrangedSubview(topicTitleTextView)
        stackView.addArrangedSubview(metadataHorizontalStack)
        stackView.addArrangedSubview(topicCommentTextView)

        activeUsersStack.addArrangedSubview(activeUsersImageView)
        activeUsersStack.addArrangedSubview(activeUsersLabel)
        repliesStack.addArrangedSubview(repliesImageView)
        repliesStack.addArrangedSubview(repliesCountLabel)

        metadataHorizontalStack.addArrangedSubview(timestampLabel)
        metadataHorizontalStack.addArrangedSubview(variableMetadataCenterSpacer)
        metadataHorizontalStack.addArrangedSubview(activeUsersStack)
        metadataHorizontalStack.addArrangedSubview(metadataSpacer)
        metadataHorizontalStack.addArrangedSubview(repliesStack)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.accessibilityElements = [topicTitleTextView, subscribeButton, disclosureButton, timestampLabel, activeUsersLabel, repliesCountLabel, topicCommentTextView]
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel) {
        self.viewModel = viewModel

        let showingOtherContent = viewModel.leadComment == nil && viewModel.otherContentHtml != nil
        let shouldHideSubscribe = !viewModel.isUserPermanent || viewModel.topicTitleHtml.isEmpty || (showingOtherContent)
        
        switch (shouldHideSubscribe, showingOtherContent) {
        case (false, false):
            updateForNewDisplayModeIfNeeded(displayMode: .subscribeMetadataReplies)
        case (true, false):
            updateForNewDisplayModeIfNeeded(displayMode: .metadataReplies)
        case (_, true):
            updateForNewDisplayModeIfNeeded(displayMode: .none)
        }

        let isThreadExpanded = viewModel.isThreadExpanded
        let collapseThreadlabel = WMFLocalizedString("talk-page-collapse-thread-button", value: "Collapse thread", comment: "Accessibility label for the collapse thread button on talk pages when the thread is expanded")
        let expandThreadlabel = WMFLocalizedString("talk-page-expand-thread-button", value: "Expand thread", comment: "Accessibility label for the expand thread button on talk pages when the thread is collapsed")
        disclosureButton.setImage(isThreadExpanded ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down"), for: .normal)

        disclosureButton.accessibilityLabel = isThreadExpanded ? collapseThreadlabel : expandThreadlabel
        updateSubscribedState(cellViewModel: viewModel)
        
        topicTitleTextView.invalidateIntrinsicContentSize()
        topicTitleTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 2
        topicTitleTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail
        
        topicCommentTextView.invalidateIntrinsicContentSize()
        topicCommentTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 3
        topicCommentTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail

        if let timestampDisplay = viewModel.timestampDisplay {
            timestampLabel.text = timestampDisplay
            timestampLabel.accessibilityLabel = viewModel.accessibilityDate()
        }

        let activeUsersAccessibilityLabel = WMFLocalizedString("talk-page-active-users-accessibilty-label", value: "{{PLURAL:%1$d|%1$d active user|%1$d active users}}", comment: "Accessibility label indicating the number of active users in a thread. The %1$d argument will be replaced with the amount of active users")
        let repliesCountAccessibilityLabel = WMFLocalizedString("talk-page-replies-count-accessibilty-label", value: "{{PLURAL:%1$d|%1$d reply|%1$d replies}}", comment: "Accessibility label indicating the number of replies in a thread. The %1$d argument will be replaced with the amount of replies")

        if let count = viewModel.activeUsersCount {
            activeUsersLabel.text = String(count)
            activeUsersLabel.accessibilityLabel = String.localizedStringWithFormat(activeUsersAccessibilityLabel, count)
        }
        repliesCountLabel.text = String(viewModel.repliesCount)
        repliesCountLabel.accessibilityLabel = String.localizedStringWithFormat(repliesCountAccessibilityLabel, viewModel.repliesCount)
    }
    
    func updateSubscribedState(cellViewModel: TalkPageCellViewModel) {
        let languageCode = cellViewModel.viewModel?.siteURL.wmf_languageCode
        let talkPageTopicSubscribe = WMFLocalizedString("talk-page-subscribe-to-topic", languageCode: languageCode, value: "Subscribe", comment: "Text used on button to subscribe to talk page topic. Please prioritize for de, ar and zh wikis.")
        let talkPageTopicUnsubscribe = WMFLocalizedString("talk-page-unsubscribe-to-topic", languageCode: languageCode, value: "Unsubscribe", comment: "Text used on button to unsubscribe from talk page topic.")

        subscribeButton.setTitle(cellViewModel.isSubscribed ? talkPageTopicUnsubscribe : talkPageTopicSubscribe , for: .normal)
        subscribeButton.setImage(cellViewModel.isSubscribed ? UIImage(systemName: "bell.fill") : UIImage(systemName: "bell"), for: .normal)
    }
    
    private func updateForNewDisplayModeIfNeeded(displayMode: DisplayMode) {
        
        guard displayMode != self.displayMode else {
            return
        }
        
        // Reset
        stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        disclosureHorizontalStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        switch displayMode {
        case .subscribeMetadataReplies:
            
            disclosureHorizontalStack.addArrangedSubview(subscribeButton)
            disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
            disclosureHorizontalStack.addArrangedSubview(disclosureButton)
            
            stackView.addArrangedSubview(disclosureHorizontalStack)

            stackView.addArrangedSubview(topicTitleTextView)
            stackView.addArrangedSubview(metadataHorizontalStack)
            stackView.addArrangedSubview(topicCommentTextView)
            
            self.accessibilityElements = [topicTitleTextView, subscribeButton, disclosureButton, timestampLabel, activeUsersLabel, repliesCountLabel, topicCommentTextView]
            
        case .metadataReplies:
            
            disclosureHorizontalStack.addArrangedSubview(topicTitleTextView)
            disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
            disclosureHorizontalStack.addArrangedSubview(disclosureButton)
            
            stackView.addArrangedSubview(disclosureHorizontalStack)

            stackView.addArrangedSubview(metadataHorizontalStack)
            stackView.addArrangedSubview(topicCommentTextView)
            
            self.accessibilityElements = [topicTitleTextView, disclosureButton, timestampLabel, activeUsersLabel, repliesCountLabel, topicCommentTextView]
            
        case .none:
            
            disclosureHorizontalStack.addArrangedSubview(topicTitleTextView)
            disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
            disclosureHorizontalStack.addArrangedSubview(disclosureButton)
            
            stackView.addArrangedSubview(disclosureHorizontalStack)
            stackView.addArrangedSubview(topicCommentTextView)
            
            self.accessibilityElements = [topicTitleTextView, disclosureButton, topicCommentTextView]
        }
        
        self.displayMode = displayMode
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        
        stackView.semanticContentAttribute = semanticContentAttribute
        disclosureHorizontalStack.semanticContentAttribute = semanticContentAttribute
        subscribeButton.semanticContentAttribute = semanticContentAttribute
        disclosureButton.semanticContentAttribute = semanticContentAttribute
        disclosureCenterSpacer.semanticContentAttribute = semanticContentAttribute
        topicTitleTextView.semanticContentAttribute = semanticContentAttribute
        timestampLabel.semanticContentAttribute = semanticContentAttribute
        topicCommentTextView.semanticContentAttribute = semanticContentAttribute
        metadataHorizontalStack.semanticContentAttribute = semanticContentAttribute
        metadataSpacer.semanticContentAttribute = semanticContentAttribute
        activeUsersStack.semanticContentAttribute = semanticContentAttribute
        activeUsersImageView.semanticContentAttribute = semanticContentAttribute
        activeUsersLabel.semanticContentAttribute = semanticContentAttribute
        repliesStack.semanticContentAttribute = semanticContentAttribute
        repliesImageView.semanticContentAttribute = semanticContentAttribute
        repliesCountLabel.semanticContentAttribute = semanticContentAttribute
        variableMetadataCenterSpacer.semanticContentAttribute = semanticContentAttribute
        
        topicTitleTextView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        topicCommentTextView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        timestampLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        activeUsersLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        repliesCountLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        
        var deprecatedSubscribeButton = subscribeButton as DeprecatedButton
        let inset: CGFloat = 2
        switch semanticContentAttribute {
        case .forceRightToLeft:
            deprecatedSubscribeButton.deprecatedContentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            deprecatedSubscribeButton.deprecatedImageEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
            deprecatedSubscribeButton.deprecatedTitleEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        default:
            deprecatedSubscribeButton.deprecatedContentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            deprecatedSubscribeButton.deprecatedImageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
            deprecatedSubscribeButton.deprecatedTitleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        }
    }

    // MARK: - Find in page

    private func applyTextHighlightIfNecessary(theme: Theme) {
        let activeHighlightBackgroundColor: UIColor = WMFColor.yellow600
        let backgroundHighlightColor: UIColor
        let foregroundHighlightColor: UIColor

        switch theme {
        case .black, .dark:
            backgroundHighlightColor = activeHighlightBackgroundColor.withAlphaComponent(0.6)
            foregroundHighlightColor = theme.colors.midBackground
        default:
            backgroundHighlightColor = activeHighlightBackgroundColor.withAlphaComponent(0.4)
            foregroundHighlightColor = theme.colors.primaryText
        }

        topicTitleTextView.attributedText = NSMutableAttributedString(attributedString: topicTitleTextView.attributedText).highlight(viewModel?.highlightText, backgroundColor: backgroundHighlightColor, foregroundColor: foregroundHighlightColor)
        topicCommentTextView.attributedText = NSMutableAttributedString(attributedString: topicCommentTextView.attributedText).highlight(viewModel?.highlightText, backgroundColor: backgroundHighlightColor, foregroundColor: foregroundHighlightColor)

        if let cellViewModel = viewModel, let activeResult = cellViewModel.activeHighlightResult {
            switch activeResult.location {
            case .topicTitle(_, let id):
                if id == cellViewModel.id {
                    topicTitleTextView.attributedText = NSMutableAttributedString(attributedString: topicTitleTextView.attributedText).highlight(viewModel?.highlightText, backgroundColor: activeHighlightBackgroundColor, targetRange: activeResult.range)
                }
            case .topicLeadComment(_, let id):
                if let leadComment = cellViewModel.leadComment,
                   id == leadComment.id {
                    topicCommentTextView.attributedText = NSMutableAttributedString(attributedString: topicCommentTextView.attributedText).highlight(viewModel?.highlightText, backgroundColor: activeHighlightBackgroundColor, targetRange: activeResult.range)
                }
            case .topicOtherContent:
                topicCommentTextView.attributedText = NSMutableAttributedString(attributedString: topicCommentTextView.attributedText).highlight(viewModel?.highlightText, backgroundColor: activeHighlightBackgroundColor, targetRange: activeResult.range)
            default:
                break
            }
        }
    }

    /// Frame converted to containing collection view
    func frameForHighlight(result: TalkPageFindInPageSearchController.SearchResult) -> CGRect? {
        guard let range = result.range else {
            return nil
        }

        switch result.location {
        case .topicTitle:
            guard let initialFrame = topicTitleTextView.frame(of: range) else {
                return nil
            }
            return topicTitleTextView.convert(initialFrame, to: rootCollectionView())
        case .topicLeadComment, .topicOtherContent:
            guard let initialFrame = topicCommentTextView.frame(of: range) else {
                return nil
            }
            return topicCommentTextView.convert(initialFrame, to: rootCollectionView())

        default:
            return nil
        }
    }

    /// Containing collection view
    private func rootCollectionView() -> UIView? {
        var sv = superview
        while !(sv is UICollectionView) {
            sv = sv?.superview
        }
        return sv
    }

}

extension TalkPageCellTopicView: Themeable {

    func apply(theme: Theme) {
        subscribeButton.tintColor = theme.colors.link
        subscribeButton.setTitleColor(theme.colors.link, for: .normal)
        disclosureButton.tintColor = theme.colors.secondaryText

        topicTitleTextView.attributedText = viewModel?.topicTitleAttributedString(traitCollection: traitCollection, theme: theme)
        topicTitleTextView.backgroundColor = theme.colors.paperBackground
        topicTitleTextView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        
        timestampLabel.textColor = theme.colors.secondaryText

        if viewModel?.leadComment != nil {
            topicCommentTextView.attributedText = viewModel?.leadCommentAttributedString(traitCollection: traitCollection, theme: theme)
        } else if viewModel?.otherContentHtml != nil {
            topicCommentTextView.attributedText = viewModel?.otherContentAttributedString(traitCollection: traitCollection, theme: theme)
        }

        topicCommentTextView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        topicCommentTextView.backgroundColor = theme.colors.paperBackground

        applyTextHighlightIfNecessary(theme: theme)

        activeUsersImageView.tintColor = theme.colors.secondaryText
        activeUsersLabel.textColor = theme.colors.secondaryText
        repliesImageView.tintColor = theme.colors.secondaryText
        repliesCountLabel.textColor = theme.colors.secondaryText
    }
    
}

extension TalkPageCellTopicView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }
}
