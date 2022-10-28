import UIKit
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
        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .semibold, size: 15)
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
        textView.delegate = self
        return textView
    }()

    lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
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
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
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
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
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
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel) {
        self.viewModel = viewModel

        let showingOtherContent = viewModel.leadComment == nil && viewModel.otherContent != nil
        let shouldHideSubscribe = !viewModel.isUserLoggedIn || viewModel.topicTitle.isEmpty || (showingOtherContent)
        
        switch (shouldHideSubscribe, showingOtherContent) {
        case (false, false):
            updateForNewDisplayModeIfNeeded(displayMode: .subscribeMetadataReplies)
        case (true, false):
            updateForNewDisplayModeIfNeeded(displayMode: .metadataReplies)
        case (_, true):
            updateForNewDisplayModeIfNeeded(displayMode: .none)
        }

        disclosureButton.setImage(viewModel.isThreadExpanded ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down"), for: .normal)

        updateSubscribedState(cellViewModel: viewModel)
        
        topicTitleTextView.invalidateIntrinsicContentSize()
        topicTitleTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 2
        topicTitleTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail
        
        topicCommentTextView.invalidateIntrinsicContentSize()
        topicCommentTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 3
        topicCommentTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail

        if let timestampDisplay = viewModel.timestampDisplay {
            timestampLabel.text = timestampDisplay
        }
        
        activeUsersLabel.text = viewModel.activeUsersCount
        repliesCountLabel.text = viewModel.repliesCount
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
            
        case .metadataReplies:
            
            disclosureHorizontalStack.addArrangedSubview(topicTitleTextView)
            disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
            disclosureHorizontalStack.addArrangedSubview(disclosureButton)
            
            stackView.addArrangedSubview(disclosureHorizontalStack)

            stackView.addArrangedSubview(metadataHorizontalStack)
            stackView.addArrangedSubview(topicCommentTextView)
            
        case .none:
            
            disclosureHorizontalStack.addArrangedSubview(topicTitleTextView)
            disclosureHorizontalStack.addArrangedSubview(disclosureCenterSpacer)
            disclosureHorizontalStack.addArrangedSubview(disclosureButton)
            
            stackView.addArrangedSubview(disclosureHorizontalStack)
            stackView.addArrangedSubview(topicCommentTextView)
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
        
        let inset: CGFloat = 2
        switch semanticContentAttribute {
        case .forceRightToLeft:
            subscribeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            subscribeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
            subscribeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        default:
            subscribeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            subscribeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
            subscribeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        }
    }

}

extension TalkPageCellTopicView: Themeable {

    func apply(theme: Theme) {
        subscribeButton.tintColor = theme.colors.link
        subscribeButton.setTitleColor(theme.colors.link, for: .normal)
        disclosureButton.tintColor = theme.colors.secondaryText

        topicTitleTextView.attributedText = viewModel?.topicTitle.byAttributingHTML(with: .headline, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: false, handlingSuperSubscripts: true)
        topicTitleTextView.backgroundColor = theme.colors.paperBackground
        
        timestampLabel.textColor = theme.colors.secondaryText
        
        let commentColor = (viewModel?.isThreadExpanded ?? false) ? theme.colors.primaryText : theme.colors.secondaryText
        
        let bodyText = viewModel?.leadComment?.text ?? viewModel?.otherContent
        topicCommentTextView.attributedText = bodyText?.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: commentColor, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true).removingInitialNewlineCharacters()
        topicCommentTextView.backgroundColor = theme.colors.paperBackground

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
