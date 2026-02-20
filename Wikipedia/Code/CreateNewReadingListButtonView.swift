import WMFComponents

public class CreateNewReadingListButtonView: UICollectionReusableView {
    @IBOutlet weak var button: AlignedImageButton!

    public override func awakeFromNib() {
        super.awakeFromNib()
        button.setImage(#imageLiteral(resourceName: "plus"), for: .normal)
        updateFonts()
        button.horizontalSpacing = 7

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateFonts()
        }
    }

    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    private func updateFonts() {
        button.titleLabel?.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
    }

}

extension CreateNewReadingListButtonView: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.tintColor = theme.colors.link
    }
}
