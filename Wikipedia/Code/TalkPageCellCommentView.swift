import UIKit
import WMF

final class TalkPageCellCommentView: SetupView {

    // MARK: - UI Elements

    lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .top
        return stackView
    }()

    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.spacing = 4
        return stackView
    }()

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
        button.setTitle(CommonStrings.talkPageReply, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .semibold, size: 15)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        
        button.addTarget(self, action: #selector(tappedReply), for: .touchUpInside)
        return button
    }()

    lazy var replyDepthView = TalkPageCellCommentDepthIndicator(depth: 0)
    
    weak var viewModel: TalkPageCellCommentViewModel?
    weak var replyDelegate: TalkPageCellReplyDelegate?
    weak var linkDelegate: TalkPageTextViewLinkHandling?

    // MARK: - Lifecycle

    override func setup() {
        addSubview(horizontalStackView)

        horizontalStackView.addArrangedSubview(replyDepthView)
        horizontalStackView.addArrangedSubview(verticalStackView)
        verticalStackView.addArrangedSubview(commentTextView)
        verticalStackView.addArrangedSubview(replyButton)

        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        self.viewModel = viewModel
        replyDepthView.label.text = " \(viewModel.replyDepth) "
    }
    
    // MARK: - Actions
    
    @objc private func tappedReply() {
        
        guard let viewModel = viewModel else {
            return
        }
        
        replyDelegate?.tappedReply(commentViewModel: viewModel)
    }

}

extension TalkPageCellCommentView: Themeable {

    func apply(theme: Theme) {
        replyDepthView.apply(theme: theme)
        
        commentTextView.attributedText = viewModel?.text.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
        commentTextView.backgroundColor = theme.colors.paperBackground
        
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
