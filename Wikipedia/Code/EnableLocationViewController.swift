import UIKit

protocol EnableLocationViewControllerDelegate: NSObjectProtocol {
    func enableLocationViewController(_ enableLocationViewController: EnableLocationViewController, didFinishWithShouldPromptForLocationAccess  shouldPromptForLocationAccess: Bool)
}

class EnableLocationViewController: UIViewController, Themeable {
    weak var delegate: EnableLocationViewControllerDelegate?
    
    @IBOutlet weak var enableLocationAccessButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @objc var shouldPrompt = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = CommonStrings.localizedEnableLocationTitle
        descriptionLabel.text = CommonStrings.localizedEnableLocationDescription
        enableLocationAccessButton.setTitle(CommonStrings.localizedEnableLocationButtonTitle, for: .normal)
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
    
}
