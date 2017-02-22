import UIKit

protocol EnableLocationViewControllerDelegate: NSObjectProtocol {
    func enableLocationViewControllerWantsToEnableLocation(_ enableLocationViewController: EnableLocationViewController)
}
class EnableLocationViewController: UIViewController {

    weak var delegate: EnableLocationViewControllerDelegate?
    
    @IBOutlet weak var enableLocationAccessButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-enable-location-title")
        descriptionLabel.text = localizedStringForKeyFallingBackOnEnglish("places-enable-location-description")
        enableLocationAccessButton.setTitle(localizedStringForKeyFallingBackOnEnglish("places-enable-location-action-button-title"), for: .normal)
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func enableLocationAccess(_ sender: Any) {
        delegate?.enableLocationViewControllerWantsToEnableLocation(self)
    }
}
