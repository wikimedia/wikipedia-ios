import WMFComponents
import WMF

final class TalkPageCellCommentView: SetupView {

    // MARK: - UI Elements

    lazy var commentTextView: UITextView = {
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

    lazy var replyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)

        button.titleLabel?.font = WMFFont.for(.boldCallout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        
        button.addTarget(self, action: #selector(tappedReply), for: .touchUpInside)
        return button
    }()

    lazy var replyDepthView: TalkPageCellReplyDepthIndicator = {
        let depthIndicator = TalkPageCellReplyDepthIndicator(depth: 0)
        depthIndicator.translatesAutoresizingMaskIntoConstraints = false
        return depthIndicator
    }()
    
    weak var viewModel: TalkPageCellCommentViewModel?
    weak var replyDelegate: TalkPageCellReplyDelegate?
    weak var linkDelegate: TalkPageTextViewLinkHandling?
    
    private var commentLeadingConstraint: NSLayoutConstraint?
    
    override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            updateSemanticContentAttribute(semanticContentAttribute)
        }
    }

    // MARK: - Lifecycle

    override func setup() {
        addSubview(replyDepthView)
        addSubview(commentTextView)
        addSubview(replyButton)
        
        let commentLeadingConstraint = commentTextView.leadingAnchor.constraint(equalTo: replyDepthView.trailingAnchor, constant: 10)
        self.commentLeadingConstraint = commentLeadingConstraint

        NSLayoutConstraint.activate([
            replyDepthView.topAnchor.constraint(equalTo: commentTextView.topAnchor),
            replyDepthView.leadingAnchor.constraint(equalTo: leadingAnchor),
            replyDepthView.bottomAnchor.constraint(equalTo: replyButton.bottomAnchor),

            commentLeadingConstraint,
            commentTextView.topAnchor.constraint(equalTo: topAnchor),
            commentTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            commentTextView.bottomAnchor.constraint(equalTo: replyButton.topAnchor),

            replyButton.leadingAnchor.constraint(equalTo: commentTextView.leadingAnchor),
            replyButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        self.viewModel = viewModel
        commentLeadingConstraint?.constant = viewModel.replyDepth > 0 ? 10 : 0
        replyDepthView.configure(viewModel: viewModel)
        
        let languageCode = viewModel.cellViewModel?.viewModel?.siteURL.wmf_languageCode
        replyButton.setTitle(CommonStrings.talkPageReply(languageCode: languageCode), for: .normal)
        let replyButtonAccessibilityLabel = CommonStrings.talkPageReplyAccessibilityText
        replyButton.accessibilityLabel = String.localizedStringWithFormat(replyButtonAccessibilityLabel, viewModel.author)
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        commentTextView.semanticContentAttribute = semanticContentAttribute
        replyButton.semanticContentAttribute = semanticContentAttribute
        replyDepthView.semanticContentAttribute = semanticContentAttribute
        
        commentTextView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        
        var deprecatedReplyButton = replyButton as DeprecatedButton
        switch semanticContentAttribute {
        case .forceRightToLeft:
            deprecatedReplyButton.deprecatedContentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            deprecatedReplyButton.deprecatedImageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            deprecatedReplyButton.deprecatedTitleEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        default:
            deprecatedReplyButton.deprecatedContentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            deprecatedReplyButton.deprecatedImageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            deprecatedReplyButton.deprecatedTitleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        }
        
    }
    
    // MARK: - Actions
    
    @objc private func tappedReply() {
        
        guard let viewModel = viewModel else {
            return
        }
        
        replyDelegate?.tappedReply(commentViewModel: viewModel, accessibilityFocusView: commentTextView)
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

        commentTextView.attributedText = NSMutableAttributedString(attributedString: commentTextView.attributedText).highlight(viewModel?.cellViewModel?.highlightText, backgroundColor: backgroundHighlightColor, foregroundColor: foregroundHighlightColor)

        if let commentViewModel = viewModel, let activeResult = commentViewModel.cellViewModel?.activeHighlightResult {
            switch activeResult.location {
            case .reply(_, _, _, let id):
                if id == commentViewModel.id {
                    commentTextView.attributedText = NSMutableAttributedString(attributedString: commentTextView.attributedText).highlight(viewModel?.cellViewModel?.highlightText, backgroundColor: activeHighlightBackgroundColor, targetRange: activeResult.range)
                }
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
        case .reply:
            guard let initialFrame = commentTextView.frame(of: range) else {
                return nil
            }
            return commentTextView.convert(initialFrame, to: rootCollectionView())
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

extension TalkPageCellCommentView: Themeable {

    func apply(theme: Theme) {
        replyDepthView.apply(theme: theme)

        commentTextView.attributedText = viewModel?.commentAttributedString(traitCollection: traitCollection, theme: theme)
        commentTextView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        commentTextView.backgroundColor = theme.colors.paperBackground
        applyTextHighlightIfNecessary(theme: theme)

        replyButton.tintColor = theme.colors.link
        replyButton.setTitleColor(theme.colors.link, for: .normal)
    }

}

extension TalkPageCellCommentView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }
}
