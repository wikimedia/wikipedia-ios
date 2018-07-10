public class CreateNewReadingListButtonView: UIView {
    @IBOutlet private weak var button: AlignedImageButton!
    @IBOutlet private weak var separator: UIView!

    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        }
    }

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {
        button.addTarget(target, action: action, for: controlEvents)
    }

}

extension CreateNewReadingListButtonView: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.colors.chromeBackground
        button.tintColor = theme.colors.link
        separator.backgroundColor = theme.colors.border
    }
}
