import UIKit
import WMF

final class TalkPageCellDisclosureRow: SetupView {

    // MARK: - UI Elements

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

    lazy var centerSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 99999)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        return view
    }()

    lazy var disclosureButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .black
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Setup

    override func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(subscribeButton)
        stackView.addArrangedSubview(centerSpacer)
        stackView.addArrangedSubview(disclosureButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellViewModel) {
        disclosureButton.setImage(viewModel.isThreadExpanded ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down"), for: .normal)

        let talkPageTopicSubscribe = WMFLocalizedString("talk-page-subscribe-to-topic", value: "Subscribe", comment: "Text used on button to subscribe to talk page topic.")
        let talkPageTopicUnsubscribe = WMFLocalizedString("talk-page-unsubscribe-to-topic", value: "Unsubscribe", comment: "Text used on button to unsubscribe from talk page topic.")

        subscribeButton.setTitle(viewModel.isSubscribed ? talkPageTopicUnsubscribe : talkPageTopicSubscribe , for: .normal)
        subscribeButton.setImage(viewModel.isSubscribed ? UIImage(systemName: "bell.fill") : UIImage(systemName: "bell"), for: .normal)
    }
    
}

extension TalkPageCellDisclosureRow: Themeable {

    func apply(theme: Theme) {
        subscribeButton.tintColor = theme.colors.link
        subscribeButton.setTitleColor(theme.colors.link, for: .normal)
        disclosureButton.tintColor = theme.colors.secondaryText
    }

}
