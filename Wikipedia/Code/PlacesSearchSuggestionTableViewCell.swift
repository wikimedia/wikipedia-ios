import UIKit

class PlacesSearchSuggestionTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()
        apply(theme: Theme.standard)
    }
}

extension PlacesSearchSuggestionTableViewCell: Themeable {
    func apply(theme: Theme) {
        backgroundView?.backgroundColor = theme.colors.paperBackground
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        detailLabel.textColor = theme.colors.secondaryText
        iconImageView.tintColor = theme.colors.secondaryText
    }
}
