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

    var textViewPlaceholderText: String? {
        didSet {
            textView.placeholder = textViewPlaceholderText
        }
    }

    var textViewTag: Int = 0 {
        didSet {
            textView.tag = textViewTag
        }
    }

    var textViewDelegate: UITextViewDelegate? {
        didSet {
            textView._delegate = textViewDelegate
        }
    }

    var footerText: String? {
        didSet {
            footerLabel.text = footerText
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerLabel.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: traitCollection)
        footerLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        textView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
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

