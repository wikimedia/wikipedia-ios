import UIKit

class WMFTitledExploreSectionFooter: WMFExploreCollectionReusableView, Themeable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var enableLocationButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        wmf_configureSubviewsForDynamicType()
    }
    
    func apply(theme: Theme) {
        titleLabel.textColor = theme.text
        descriptionLabel.textColor = theme.secondaryText
        backgroundColor = theme.midBackground
        enableLocationButton.borderColor = theme.link
    }
}
