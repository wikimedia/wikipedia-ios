import UIKit
import WMF


class TalkPageFormattingToolbarView: SetupView {

    weak var delegate: TalkPageFormattingToolbarViewDelegate?

    lazy var boldButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "text-formatting-bold"), for: .normal)
        button.masksToBounds = true
        return button
    }()

    lazy var italicsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "text-formatting-italics"), for: .normal)
        button.masksToBounds = true
        return button
    }()

    lazy var imageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "photo"), for: .normal)
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

    lazy var separatorView: UIView =  {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        return view
    }()
    lazy var stackView: UIStackView = {
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
        stackView.addArrangedSubview(boldButton)
        stackView.addArrangedSubview(italicsButton)
        stackView.addArrangedSubview(imageButton)
        stackView.addArrangedSubview(linkButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
        imageButton.tintColor = theme.colors.inputAccessoryButtonTint
        linkButton.tintColor = theme.colors.inputAccessoryButtonTint
    }

}
