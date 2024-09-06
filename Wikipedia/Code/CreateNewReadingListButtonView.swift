import WMFComponents

public class CreateNewReadingListButtonView: UIView {
    @IBOutlet weak var button: AlignedImageButton!
    @IBOutlet private weak var separator: UIView!

    public override func awakeFromNib() {
        super.awakeFromNib()
        button.setImage(#imageLiteral(resourceName: "plus"), for: .normal)
        updateFonts()
        button.horizontalSpacing = 7
    }

    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        button.titleLabel?.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
    }

}

extension CreateNewReadingListButtonView: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.tintColor = theme.colors.link
        separator.backgroundColor = theme.colors.border
    }
}
