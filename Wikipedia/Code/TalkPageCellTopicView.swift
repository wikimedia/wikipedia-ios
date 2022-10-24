import UIKit
import WMF

final class TalkPageCellTopicView: SetupView {

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

        let inset: CGFloat = 2
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)

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
    
    private weak var viewModel: TalkPageCellViewModel?
    weak var linkDelegate: TalkPageTextViewLinkHandling?

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel) {
        self.viewModel = viewModel

        configureDisclosureRow(isUserLoggedIn: viewModel.isUserLoggedIn)

        disclosureButton.setImage(viewModel.isThreadExpanded ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down"), for: .normal)

        updateSubscribedState(viewModel: viewModel)
        
        topicTitleTextView.invalidateIntrinsicContentSize()
        topicTitleTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 2
        topicTitleTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail
        
        topicCommentTextView.invalidateIntrinsicContentSize()
        topicCommentTextView.textContainer.maximumNumberOfLines = viewModel.isThreadExpanded ? 0 : 3
        topicCommentTextView.textContainer.lineBreakMode = viewModel.isThreadExpanded ? .byWordWrapping : .byTruncatingTail

        if let timestamp = viewModel.timestamp {
            timestampLabel.text = DateFormatter.wmf_utcMediumDateFormatterWithoutTime().string(from: timestamp)
        }
        
        activeUsersLabel.text = viewModel.activeUsersCount
        repliesCountLabel.text = viewModel.repliesCount
    }
    
    func updateSubscribedState(viewModel: TalkPageCellViewModel) {
        let talkPageTopicSubscribe = WMFLocalizedString("talk-page-subscribe-to-topic", value: "Subscribe", comment: "Text used on button to subscribe to talk page topic. Please prioritize for de, ar and zh wikis.")
        let talkPageTopicUnsubscribe = WMFLocalizedString("talk-page-unsubscribe-to-topic", value: "Unsubscribe", comment: "Text used on button to unsubscribe from talk page topic.")

        subscribeButton.setTitle(viewModel.isSubscribed ? talkPageTopicUnsubscribe : talkPageTopicSubscribe , for: .normal)
        subscribeButton.setImage(viewModel.isSubscribed ? UIImage(systemName: "bell.fill") : UIImage(systemName: "bell"), for: .normal)
    }

    fileprivate func configureDisclosureRow(isUserLoggedIn: Bool) {
        if isUserLoggedIn {
            if disclosureHorizontalStack.arrangedSubviews.contains(topicTitleTextView) {
                topicTitleTextView.removeFromSuperview()
                disclosureHorizontalStack.insertArrangedSubview(subscribeButton, at: 0)
                stackView.insertArrangedSubview(topicTitleTextView, at: 1)
            }
        } else {
            if disclosureHorizontalStack.arrangedSubviews.contains(subscribeButton) {
                subscribeButton.removeFromSuperview()
                disclosureHorizontalStack.insertArrangedSubview(topicTitleTextView, at: 0)
            }

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
        topicCommentTextView.attributedText = viewModel?.leadComment.text.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: commentColor, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
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
