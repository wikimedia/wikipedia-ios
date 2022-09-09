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
        stackView.distribution = .fillProportionally
        stackView.spacing = 4
        return stackView
    }()

    lazy var commentLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        // TODO: - Something off with these...
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 0
        return label
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
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)

        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .semibold, size: 15)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        
        button.addTarget(self, action: #selector(tappedReply), for: .touchUpInside)
        return button
    }()

    lazy var replyDepthView = TalkPageCellReplyDepthIndicator(depth: 0)
    
    weak var viewModel: TalkPageCellCommentViewModel?
    weak var replyDelegate: TalkPageCellReplyDelegate?

    // MARK: - Lifecycle

    override func setup() {
        addSubview(horizontalStackView)

        horizontalStackView.addArrangedSubview(replyDepthView)
        horizontalStackView.addArrangedSubview(verticalStackView)
        verticalStackView.addArrangedSubview(commentLabel)
        verticalStackView.addArrangedSubview(replyButton)

        let replyDepthWidthConstraint = replyDepthView.widthAnchor.constraint(lessThanOrEqualTo: horizontalStackView.widthAnchor, constant: 1/2)
        replyDepthWidthConstraint.priority = .required

        let replyDepthHeightConstraint = replyDepthView.heightAnchor.constraint(equalTo: horizontalStackView.heightAnchor)
        replyDepthHeightConstraint.priority = .required

        let commentLabelWidthConstraint = commentLabel.widthAnchor.constraint(greaterThanOrEqualTo: horizontalStackView.widthAnchor, multiplier: 1/2)
        commentLabelWidthConstraint.priority = .required

        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            replyDepthWidthConstraint,
            replyDepthHeightConstraint,
            commentLabelWidthConstraint
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        self.viewModel = viewModel
        commentLabel.text = viewModel.text
        replyDepthView.configure(viewModel: viewModel)
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
        
        commentLabel.textColor = theme.colors.primaryText
        replyButton.tintColor = theme.colors.link
        replyButton.setTitleColor(theme.colors.link, for: .normal)
    }

}
