import UIKit

protocol EnableLocationViewControllerDelegate: NSObjectProtocol {
    func enableLocationViewController(_ enableLocationViewController: EnableLocationViewController, didFinishWithShouldPromptForLocationAccess  shouldPromptForLocationAccess: Bool)
}
class EnableLocationViewController: UIViewController {

    weak var delegate: EnableLocationViewControllerDelegate?
    
    @IBOutlet weak var enableLocationAccessButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var shouldPrompt = false
    
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
        shouldPrompt = true
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.enableLocationViewController(self, didFinishWithShouldPromptForLocationAccess: shouldPrompt)
    }
}
