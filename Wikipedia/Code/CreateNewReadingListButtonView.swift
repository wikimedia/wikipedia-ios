public class CreateNewReadingListButtonView: SetupView {
    public let button = AlignedImageButton(type: .system)
    public override func setup() {
        super.setup()
        translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(CommonStrings.createNewListTitle, for: .normal)
        button.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        let centerX = centerXAnchor.constraint(equalTo: button.centerXAnchor)
        let centerY = centerYAnchor.constraint(equalTo: button.centerYAnchor)
        let heightConstraint = heightAnchor.constraint(equalToConstant: 50)
        NSLayoutConstraint.activate([centerX, centerY, heightConstraint])
    }
}

extension CreateNewReadingListButtonView: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.tintColor = theme.colors.link
    }
}
