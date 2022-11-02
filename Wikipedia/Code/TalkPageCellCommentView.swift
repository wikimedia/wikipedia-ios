import UIKit
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
        button.setTitle(CommonStrings.talkPageReply, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)

        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .semibold, size: 15)
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
    }
    
    // MARK: - Actions
    
    @objc private func tappedReply() {
        
        guard let viewModel = viewModel else {
            return
        }
        
        replyDelegate?.tappedReply(commentViewModel: viewModel)
    }

    // MARK: - Find in page

    private func applyTextHighlightIfNecessary(theme: Theme) {
        let activeHighlightBackgroundColor: UIColor = .yellow50
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

}

extension TalkPageCellCommentView: Themeable {

    func apply(theme: Theme) {
        replyDepthView.apply(theme: theme)

        commentTextView.attributedText = viewModel?.text.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
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
