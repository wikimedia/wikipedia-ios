import UIKit

class EnableLocationPanelViewController : EducationPopoverPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = UIImage.init(named: "places-auth-arrow")
        titleLabel.text = CommonStrings.localizedEnableLocationTitle
        primaryButton.setTitle(CommonStrings.localizedEnableLocationButtonTitle, for: .normal)
        descriptionLabel.text = CommonStrings.localizedEnableLocationDescription
    }
}
