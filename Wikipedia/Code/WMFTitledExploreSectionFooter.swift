import UIKit

class WMFTitledExploreSectionFooter: WMFExploreCollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var enableLocationButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        wmf_configureSubviewsForDynamicType()
    }
}
