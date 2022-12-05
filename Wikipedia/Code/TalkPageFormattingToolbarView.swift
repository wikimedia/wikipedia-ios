import UIKit
import WMF

final class TalkPageFormattingToolbarView: SetupView {

    weak internal var delegate: TalkPageFormattingToolbarViewDelegate?

    lazy private var boldButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "text-formatting-bold"), for: .normal)
        button.masksToBounds = true
        return button
    }()

    lazy private var italicsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "text-formatting-italics"), for: .normal)
        button.masksToBounds = true
        return button
    }()

    lazy var linkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "link"), for: .normal)
        button.masksToBounds = true
        return button
    }()

    lazy private var boldButtonSeparatorView: UIView =  {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        return view
    }()

    lazy private var boldButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.axis = .horizontal
        return stackView
    }()

    lazy private var italicsButtonSeparatorView: UIView =  {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        return view
    }()

    lazy private var italicsButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.axis = .horizontal
        return stackView
    }()

    lazy private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        return stackView
    }()

    init() {
        super.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        addSubview(stackView)

        stackView.addArrangedSubview(boldButtonStackView)
        stackView.addArrangedSubview(italicsButtonStackView)
        boldButtonStackView.addArrangedSubview(boldButton)
        boldButtonStackView.addArrangedSubview(boldButtonSeparatorView)
        italicsButtonStackView.addArrangedSubview(italicsButton)
        italicsButtonStackView.addArrangedSubview(italicsButtonSeparatorView)

        stackView.addArrangedSubview(linkButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            boldButton.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            italicsButton.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),

            boldButtonSeparatorView.heightAnchor.constraint(equalTo: boldButton.heightAnchor, constant: -20),
            boldButtonSeparatorView.widthAnchor.constraint(equalToConstant: 0.5),
            boldButtonSeparatorView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),

            italicsButtonSeparatorView.heightAnchor.constraint(equalTo: italicsButton.heightAnchor, constant: -20),
            italicsButtonSeparatorView.widthAnchor.constraint(equalToConstant: 0.5),
            italicsButtonSeparatorView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)
        ])
        configure()

    }

    @objc private func didTapBoldButton() {
        delegate?.didSelectBold()
    }

    @objc private func didTapItalicsButton() {
        delegate?.didSelectItalics()
    }

    @objc private func didTapInsertLinkButton() {
        delegate?.didSelectInsertLink()
    }

    private func configure() {
        boldButton.addTarget(self, action: #selector(didTapBoldButton), for: .touchUpInside)
        italicsButton.addTarget(self, action: #selector(didTapItalicsButton), for: .touchUpInside)
        linkButton.addTarget(self, action: #selector(didTapInsertLinkButton), for: .touchUpInside)
    }
}

extension TalkPageFormattingToolbarView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.inputAccessoryBackground

        if theme.hasInputAccessoryShadow {
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 10
            layer.shadowOpacity = 1.0
            layer.shadowColor = theme.colors.shadow.cgColor
        } else {
            layer.shadowOffset = .zero
            layer.shadowRadius = 0
            layer.shadowOpacity = 0
            layer.shadowColor = nil
        }

        boldButton.tintColor = theme.colors.inputAccessoryButtonTint
        italicsButton.tintColor = theme.colors.inputAccessoryButtonTint
        linkButton.tintColor = theme.colors.inputAccessoryButtonTint
        boldButtonSeparatorView.backgroundColor = theme.colors.secondaryText
        boldButtonSeparatorView.alpha = 0.8
        italicsButtonSeparatorView.backgroundColor = theme.colors.secondaryText
        italicsButtonSeparatorView.alpha = 0.8
    }

}
