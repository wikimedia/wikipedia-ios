import WMFComponents
import WMF

final class TalkPageErrorStateView: SetupView {

    fileprivate var titleText = WMFLocalizedString("talk-page-error-loading-title", value: "Unable to load talk page", comment: "Title text for error page on talk pages")
    fileprivate var subtitleText = WMFLocalizedString("talk-page-error-loading-subtitle", value: "Something went wrong.", comment: "Subtitle text for error page on talk pages")

    fileprivate var titleFont = WMFFont.for(.headline)
    fileprivate var subtitleFont = WMFFont.for(.footnote)
    fileprivate var buttonFont = WMFFont.for(.boldCallout)

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "talk-page-error-message"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = titleFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = subtitleFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = buttonFont
        button.cornerRadius = 8
        button.masksToBounds = true
        return button
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var imageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    override func setup() {
        addSubview(stackView)

        stackView.addArrangedSubview(imageStackView)
        imageStackView.addArrangedSubview(imageView)

        stackView.addArrangedSubview(textStackView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        textStackView.setCustomSpacing(10, after: titleLabel)
        textStackView.setCustomSpacing(20, after: subtitleLabel)

        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.addArrangedSubview(button)

        stackView.distribution = .equalSpacing

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 45),

            imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 130),
            imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 130),

            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 270),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        configure()
    }

    func configure() {
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        button.setTitle(CommonStrings.tryAgain.localizedCapitalized, for: .normal)
    }

}

extension TalkPageErrorStateView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.midBackground
        button.setTitleColor(theme.colors.paperBackground, for: .normal)
        button.backgroundColor = theme.colors.link
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.primaryText
    }
}
