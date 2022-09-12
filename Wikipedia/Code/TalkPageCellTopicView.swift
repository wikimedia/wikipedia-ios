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

    lazy var horizontalStack: UIStackView = {
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
        return imageView
    }()

    lazy var activeUsersLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
        label.numberOfLines = 0
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
        return imageView
    }()

    lazy var repliesCountLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
        label.numberOfLines = 0
        return label
    }()

    lazy var replyButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .semibold, size: 15)
        button.setTitle(CommonStrings.talkPageReply, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    lazy var centerSpacer: UIView = {
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
        stackView.addArrangedSubview(topicTitleTextView)
        stackView.addArrangedSubview(horizontalStack)
        stackView.addArrangedSubview(topicCommentTextView)
        stackView.addArrangedSubview(replyButton)

        activeUsersStack.addArrangedSubview(activeUsersImageView)
        activeUsersStack.addArrangedSubview(activeUsersLabel)
        repliesStack.addArrangedSubview(repliesImageView)
        repliesStack.addArrangedSubview(repliesCountLabel)

        horizontalStack.addArrangedSubview(timestampLabel)
        horizontalStack.addArrangedSubview(centerSpacer)
        horizontalStack.addArrangedSubview(activeUsersStack)
        horizontalStack.addArrangedSubview(metadataSpacer)
        horizontalStack.addArrangedSubview(repliesStack)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
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

}

extension TalkPageCellTopicView: Themeable {

    func apply(theme: Theme) {
        
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

        replyButton.setTitleColor(theme.colors.paperBackground, for: .normal)
        replyButton.backgroundColor = theme.colors.link
        replyButton.tintColor = theme.colors.paperBackground
    }
    
}

extension TalkPageCellTopicView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }
}
