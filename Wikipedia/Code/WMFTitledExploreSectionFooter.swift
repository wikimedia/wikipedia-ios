import UIKit

class WMFTitledExploreSectionFooter: WMFExploreCollectionReusableView {
	@IBOutlet weak var enableLocationButton: UIButton!
	
    override func awakeFromNib() {
        wmf_configureSubviewsForDynamicType()
    }
}
