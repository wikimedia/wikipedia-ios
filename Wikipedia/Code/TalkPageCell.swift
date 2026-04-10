import WMFComponents
import WMF

protocol TalkPageCellDelegate: AnyObject {
    func userDidTapDisclosureButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell)
    func userDidTapSubscribeButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell)
}

protocol TalkPageCellReplyDelegate: AnyObject {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel, accessibilityFocusView: UIView?)
}

final class TalkPageCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "TalkPageCell"

    weak var viewModel: TalkPageCellViewModel?
    weak var delegate: TalkPageCellDelegate?
    weak var replyDelegate: TalkPageCellReplyDelegate?

    // MARK: - UI Elements

    lazy var rootContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.0
        return view
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        return stackView
    }()

    lazy var leadReplySpacer = VerticalSpacerView.spacerWith(space: 16)

    lazy var leadReplyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrowshape.turn.up.left")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13)
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.cornerStyle = .capsule

        var container = AttributeContainer()
        container.font = WMFFont.for(.boldCallout)
        config.attributedTitle = AttributedString("", attributes: container)

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            button.configuration = config
        }

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }()

    lazy var topicView: TalkPageCellTopicView = TalkPageCellTopicView()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
        delegate = nil
        topicView.disclosureButton.removeTarget(nil, action: nil, for: .allEvents)
        topicView.subscribeButton.removeTarget(nil, action: nil, for: .allEvents)
        removeExpandedElements()
    }

    func setup() {
        contentView.addSubview(rootContainer)
        rootContainer.addSubview(stackView)

        let rootContainerBottomConstraint = rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        rootContainerBottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rootContainerBottomConstraint,
            rootContainer.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 8),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor, constant: -8),

            stackView.topAnchor.constraint(equalTo: rootContainer.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: -12),
            stackView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor, constant: -12)
        ])

        stackView.addArrangedSubview(topicView)
    }

    // MARK: - Public

    /// Seeks out and returns the associated comment view that is already in the cell view hierarchy.
    func commentViewForViewModel(_ commentViewModel: TalkPageCellCommentViewModel) -> TalkPageCellCommentView? {

        return stackView.arrangedSubviews
                    .compactMap { $0 as? TalkPageCellCommentView }
                    .first(where: { $0.viewModel == commentViewModel })
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel, linkDelegate: TalkPageTextViewLinkHandling) {
        self.viewModel = viewModel

        topicView.configure(viewModel: viewModel)
        topicView.linkDelegate = linkDelegate

        topicView.disclosureButton.addTarget(self, action: #selector(userDidTapDisclosureButton), for: .primaryActionTriggered)
        topicView.subscribeButton.addTarget(self, action: #selector(userDidTapSubscribeButton), for: .primaryActionTriggered)
        leadReplyButton.addTarget(self, action: #selector(userDidTapLeadReply), for: .touchUpInside)

        let languageCode = viewModel.viewModel?.siteURL.wmf_languageCode
        leadReplyButton.setTitle(CommonStrings.talkPageReply(languageCode: languageCode), for: .normal)
        let replyButtonAccessibilityLabel = CommonStrings.talkPageReplyAccessibilityText
        if let author = viewModel.leadComment?.author {
            leadReplyButton.accessibilityLabel = String.localizedStringWithFormat(replyButtonAccessibilityLabel, author)
        }

        guard let semanticContentAttribute = viewModel.viewModel?.semanticContentAttribute else {
            return
        }

        updateSemanticContentAttribute(semanticContentAttribute)

        let showingOtherContent = viewModel.leadComment == nil && viewModel.otherContentHtml != nil

        guard !showingOtherContent else {
            return
        }

        if viewModel.isThreadExpanded {

            stackView.addArrangedSubview(leadReplySpacer)
            stackView.addArrangedSubview(leadReplyButton)

            for commentViewModel in viewModel.replies {
                let separator = TalkPageCellCommentSeparator()
                separator.setContentHuggingPriority(.defaultLow, for: .horizontal)
                separator.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

                let commentView = TalkPageCellCommentView()
                commentView.replyDelegate = replyDelegate
                commentView.configure(viewModel: commentViewModel)
                commentView.linkDelegate = linkDelegate

                stackView.addArrangedSubview(separator)
                stackView.addArrangedSubview(commentView)
            }
        }
    }


    func updateSubscribedState(viewModel: TalkPageCellViewModel) {
        topicView.updateSubscribedState(cellViewModel: viewModel)
    }

    func removeExpandedElements() {
        for subview in stackView.arrangedSubviews {
            if subview != topicView {
                subview.removeFromSuperview()
            }
        }
    }

    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        stackView.semanticContentAttribute = semanticContentAttribute
        leadReplySpacer.semanticContentAttribute = semanticContentAttribute
        leadReplyButton.semanticContentAttribute = semanticContentAttribute
        topicView.semanticContentAttribute = semanticContentAttribute

        stackView.arrangedSubviews.forEach { subview in
            subview.semanticContentAttribute = semanticContentAttribute
        }
    }

    // MARK: - Actions

    @objc func userDidTapDisclosureButton() {
        delegate?.userDidTapDisclosureButton(cellViewModel: viewModel, cell: self)
    }

    @objc func userDidTapSubscribeButton() {
        delegate?.userDidTapSubscribeButton(cellViewModel: viewModel, cell: self)
    }

    @objc func userDidTapLeadReply() {

        guard let commentViewModel = viewModel?.leadComment else {
            return
        }

        replyDelegate?.tappedReply(commentViewModel: commentViewModel, accessibilityFocusView: topicView.topicCommentTextView)
    }
}

// MARK: - Themeable

extension TalkPageCell: Themeable {

    func apply(theme: Theme) {
        rootContainer.backgroundColor = theme.colors.paperBackground
        rootContainer.layer.borderColor = theme.colors.midCardBorder.cgColor

        stackView.arrangedSubviews.forEach { ($0 as? Themeable)?.apply(theme: theme) }

        var config = leadReplyButton.configuration
        config?.baseForegroundColor = theme.colors.paperBackground
        config?.baseBackgroundColor = theme.colors.link
        leadReplyButton.configuration = config

        // Need to set textView and label textAlignments in the hierarchy again, after their attributed strings are set to the correct theme.
        let currentSemanticContentAttribute = stackView.semanticContentAttribute
        updateSemanticContentAttribute(currentSemanticContentAttribute)
    }
}
