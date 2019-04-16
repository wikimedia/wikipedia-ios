import UIKit

class InsertMediaSettingsTextTableViewCell: UITableViewCell {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var textField: ThemeableTextField!
    @IBOutlet private weak var footerLabel: UILabel!

    var headerText: String? {
        didSet {
            headerLabel.text = headerText
        }
    }

    var textFieldPlaceholderText: String? {
        didSet {
            textField.placeholder = textFieldPlaceholderText
        }
    }

    var footerText: String? {
        didSet {
            footerLabel.text = footerText
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.black
    }
}

extension InsertMediaSettingsTextTableViewCell: Themeable {
    func apply(theme: Theme) {
    }
}

