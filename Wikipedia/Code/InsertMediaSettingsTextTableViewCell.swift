import UIKit

class InsertMediaSettingsTextTableViewCell: UITableViewCell {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!

    var textViewDelegate: UITextViewDelegate? {
        didSet {
            textView.delegate = textViewDelegate
        }
    }

    var headerText: String? {
        didSet {
            headerLabel.text = headerText
        }
    }

    var textFieldPlaceholderText: String? {
        didSet {
            textView.text = textFieldPlaceholderText
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
        //textField.apply(theme: theme)
    }
}

