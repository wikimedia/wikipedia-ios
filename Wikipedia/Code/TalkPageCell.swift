import Foundation
import UIKit
import WMF

protocol TalkPageCellDelegate: AnyObject {
    func userDidTapDisclosureButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell)
    func userDidTapSubscribeButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell)
}

protocol TalkPageCellReplyDelegate: AnyObject {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel)
}

final class TalkPageCellRootContainerView: SetupView, Themeable {
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
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }()

    lazy var topicView: TalkPageCellTopicView = TalkPageCellTopicView()
    lazy var disclosureRow: TalkPageCellDisclosureRow = TalkPageCellDisclosureRow()
    lazy var commentView = TalkPageCellCommentView()
    
    override func setup() {
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        stackView.addArrangedSubview(disclosureRow)
        stackView.addArrangedSubview(topicView)
        stackView.addArrangedSubview(leadReplySpacer)
        stackView.addArrangedSubview(leadReplyButton)
    }
    
    func configure(viewModel: TalkPageCellViewModel, linkDelegate: TalkPageTextViewLinkHandling, replyDelegate: TalkPageCellReplyDelegate, theme: Theme) {
        disclosureRow.configure(viewModel: viewModel)
        topicView.configure(viewModel: viewModel)
        topicView.linkDelegate = linkDelegate

        leadReplySpacer.isHidden = !viewModel.isThreadExpanded
        leadReplyButton.isHidden = !viewModel.isThreadExpanded

        let comments: [UIView] = stackView.arrangedSubviews.filter { view in view is TalkPageCellCommentView || view is TalkPageCellCommentSeparator }
        stackView.arrangedSubviews.forEach { view in
            if comments.contains(view) {
                view.removeFromSuperview()
            }
        }

        for commentViewModel in viewModel.replies {
            let separator = TalkPageCellCommentSeparator()
            separator.setContentHuggingPriority(.defaultLow, for: .horizontal)
            separator.setContentCompressionResistancePriority(.required, for: .horizontal)

            let commentView = TalkPageCellCommentView()
            commentView.replyDelegate = replyDelegate
            commentView.configure(viewModel: commentViewModel)
            commentView.linkDelegate = linkDelegate

            commentView.isHidden = !viewModel.isThreadExpanded
            separator.isHidden = !viewModel.isThreadExpanded

            stackView.addArrangedSubview(separator)
            stackView.addArrangedSubview(commentView)
        }
        
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        layer.borderColor = theme.colors.border.cgColor
        stackView.arrangedSubviews.forEach { ($0 as? Themeable)?.apply(theme: theme) }
        
        leadReplyButton.setTitleColor(theme.colors.paperBackground, for: .normal)
        leadReplyButton.backgroundColor = theme.colors.link
        leadReplyButton.tintColor = theme.colors.paperBackground
    }
}

final class TalkPageCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "TalkPageCell"

    weak var viewModel: TalkPageCellViewModel?
    weak var delegate: TalkPageCellDelegate?
    weak var replyDelegate: TalkPageCellReplyDelegate?
    
    static let padding = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

    // MARK: - UI Elements

    lazy var rootContainer: TalkPageCellRootContainerView = {
        let view = TalkPageCellRootContainerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.0
        return view
    }()


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
        viewModel = nil
        delegate = nil
        rootContainer.disclosureRow.disclosureButton.removeTarget(nil, action: nil, for: .allEvents)
        rootContainer.disclosureRow.subscribeButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    func setup() {
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.padding.top),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.padding.leading),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.padding.trailing)
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel, linkDelegate: TalkPageTextViewLinkHandling, replyDelegate: TalkPageCellReplyDelegate, theme: Theme) {
        self.viewModel = viewModel
        self.replyDelegate = replyDelegate

        rootContainer.configure(viewModel: viewModel, linkDelegate: linkDelegate, replyDelegate: replyDelegate, theme: theme)

        rootContainer.disclosureRow.disclosureButton.addTarget(self, action: #selector(userDidTapDisclosureButton), for: .primaryActionTriggered)
        rootContainer.disclosureRow.subscribeButton.addTarget(self, action: #selector(userDidTapSubscribeButton), for: .primaryActionTriggered)
        rootContainer.leadReplyButton.addTarget(self, action: #selector(userDidTapLeadReply), for: .touchUpInside)
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
        
        replyDelegate?.tappedReply(commentViewModel: commentViewModel)
    }
}

// MARK: - Themeable

extension TalkPageCell: Themeable {

    func apply(theme: Theme) {
        rootContainer.apply(theme: theme)
    }

}
