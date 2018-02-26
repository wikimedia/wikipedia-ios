import UIKit

class WMFTitledExploreSectionFooter: WMFExploreCollectionReusableView, Themeable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var enableLocationButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        wmf_configureSubviewsForDynamicType()
    }
    
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        backgroundColor = theme.colors.midBackground
        titleLabel.backgroundColor = backgroundColor
        descriptionLabel.backgroundColor = backgroundColor
        enableLocationButton.borderColor = theme.colors.link
        enableLocationButton.titleLabel?.backgroundColor = backgroundColor
    }
}
