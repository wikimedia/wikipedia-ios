import UIKit

protocol EnableLocationViewControllerDelegate: NSObjectProtocol {
    func enableLocationViewController(_ enableLocationViewController: EnableLocationViewController, didFinishWithShouldPromptForLocationAccess  shouldPromptForLocationAccess: Bool)
}

class EnableLocationViewController: UIViewController, Themeable {
    @objc static let localizedEnableLocationTitle = WMFLocalizedString("places-enable-location-title", value:"Explore articles near your location by enabling Location Access", comment:"Explains that you can explore articles near you by enabling location access. \"Location\" should be the same term, which is used in the device settings, under \"Privacy\".")
    @objc static let localizedEnableLocationExploreTitle = WMFLocalizedString("explore-enable-location-title", value:"Explore articles near your current location", comment:"Explains that you can explore articles near your current location. \"Location\" should be the same term, which is used in the device settings, under \"Privacy\".")
    @objc static let localizedEnableLocationDescription = WMFLocalizedString("places-enable-location-description", value:"Access to your location is available only when the app or one of its features is visible on your screen.", comment:"Describes that access to your location is only used when the app or one of its features is on the screen")
    @objc static let localizedEnableLocationButtonTitle = WMFLocalizedString("places-enable-location-action-button-title", value:"Enable location", comment:"Button title to enable location access")
    
    weak var delegate: EnableLocationViewControllerDelegate?
    
    @IBOutlet weak var enableLocationAccessButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @objc var shouldPrompt = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = EnableLocationViewController.localizedEnableLocationTitle
        descriptionLabel.text = EnableLocationViewController.localizedEnableLocationDescription
        enableLocationAccessButton.setTitle(EnableLocationViewController.localizedEnableLocationButtonTitle, for: .normal)
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func enableLocationAccess(_ sender: Any) {
        shouldPrompt = true
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.enableLocationViewController(self, didFinishWithShouldPromptForLocationAccess: shouldPrompt)
    }
    
    func apply(theme: Theme) {
        view.tintColor = theme.colors.link
    }
    
    @IBOutlet weak var imageToTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabelToBottomConstraint: NSLayoutConstraint!

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
        let isLandscape: Bool = UIDevice.current.orientation.isLandscape
        
        if isPhone && isLandscape {
            imageToTopConstraint.constant = 10
            descriptionLabelToBottomConstraint.constant = 10
        }
    }
}
