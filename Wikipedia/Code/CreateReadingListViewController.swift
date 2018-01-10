import UIKit

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createdNewReadingList(in controller: CreateReadingListViewController, with name: String, description: String?)
}

class CreateReadingListViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        readingListNameTextField.delegate = self
        readingListNameTextField.returnKeyType = .next
        readingListNameTextField.enablesReturnKeyAutomatically = true
        
        createReadingListButton.isEnabled = false
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: CreateReadingListDelegate?
    
    @IBAction func createReadingListButtonPressed() {
        guard let name = readingListNameTextField.text else {
            return
        }
        delegate?.createdNewReadingList(in: self, with: name, description: descriptionTextField.text)
    }
    
    // MARK: - UITextFieldDelegate
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        let isEmpty = readingListNameTextField.text?.isEmpty ?? true
        createReadingListButton.isEnabled = !isEmpty
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if readingListNameTextField.isFirstResponder {
            descriptionTextField.becomeFirstResponder()
        }
        return true
    }

}

extension CreateReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        readingListNameTextField.apply(theme: theme)
        descriptionTextField.apply(theme: theme)
        
        titleLabel.textColor = theme.colors.primaryText
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        
        createReadingListButton.apply(theme: theme)
       
    }
}
