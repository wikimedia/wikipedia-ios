import UIKit

final class InsertMediaImageEmptyView: UIView {
    @IBOutlet private weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        label.text = WMFLocalizedString("insert-media-placeholder-label-text", value: "Select or upload a file", comment: "Text for placeholder label visible when no file was selected or uploaded")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font = UIFont.wmf_font(.semiboldHeadline, compatibleWithTraitCollection: traitCollection)
    }
}

extension InsertMediaImageEmptyView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.baseBackground
        label.textColor = theme.colors.overlayText
    }
}
