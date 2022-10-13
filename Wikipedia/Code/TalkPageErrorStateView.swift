import WMF

final class TalkPageErrorStateView: SetupView {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "talk-page-error-message"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var title: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var subtitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
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

    lazy var stacktext: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var stackImage: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var stackButton: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    override func setup() {
        addSubview(stackView)

        title.text = "Title"
        subtitle.text = "Sub"
        button.setTitle("Button", for: .normal)

        stackView.addArrangedSubview(stackImage)
        stackImage.addArrangedSubview(VerticalSpacerView.spacerWith(space: 20))
        stackImage.addArrangedSubview(imageView)
        stackImage.addArrangedSubview(VerticalSpacerView.spacerWith(space: 20))

        stackView.addArrangedSubview(stacktext)
        stacktext.addArrangedSubview(title)

        stackView.addArrangedSubview(stackButton)
        stackButton.addArrangedSubview(VerticalSpacerView.spacerWith(space: 20))
        stackButton.addArrangedSubview(button)
        stackButton.addArrangedSubview(VerticalSpacerView.spacerWith(space: 20))

        stackView.setCustomSpacing(28, after: stackImage)
        stackView.setCustomSpacing(28, after: stackButton)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 45),

            imageView.heightAnchor.constraint(equalToConstant: 130),
            imageView.widthAnchor.constraint(equalToConstant: 130),

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 200),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -200),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)

        ])

    }

}

extension TalkPageErrorStateView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.baseBackground
        button.setTitleColor(theme.colors.paperBackground, for: .normal)
        button.backgroundColor = theme.colors.link
    }
}
