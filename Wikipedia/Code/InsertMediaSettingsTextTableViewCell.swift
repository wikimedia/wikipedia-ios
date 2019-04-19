import UIKit

class InsertMediaSettingsTextTableViewCell: UITableViewCell {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    @IBOutlet private weak var textView: ThemeableTextView!

    var headerText: String? {
        didSet {
            headerLabel.text = headerText
        }
    }

    var footerText: String? {
        didSet {
            footerLabel.text = footerText
        }
    }

    func textViewConfigured(with delegate: UITextViewDelegate, placeholder: String?, tag: Int) -> UITextView {
        textView._delegate = delegate
        textView.placeholder = placeholder
        textView.tag = tag
        return textView
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerLabel.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: traitCollection)
        footerLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        textView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headerLabel.text = nil
        footerLabel.text = nil
        textView.reset()
    }
}

extension InsertMediaSettingsTextTableViewCell: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headerLabel.textColor = theme.colors.secondaryText
        footerLabel.textColor = theme.colors.secondaryText
        textView.apply(theme: theme)
    }
}

