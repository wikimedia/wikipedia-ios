import UIKit

class EnableLocationPanelViewController : EducationPopoverPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "places-auth-arrow")
        heading = CommonStrings.localizedEnableLocationTitle
        primaryButtonTitle = CommonStrings.localizedEnableLocationButtonTitle
        footer = CommonStrings.localizedEnableLocationDescription
    }
}
