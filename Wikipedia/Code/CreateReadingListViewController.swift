import UIKit

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createdNewReadingList(in controller: CreateReadingListViewController, with name: String, description: String?)
}

class CreateReadingListViewController: UIViewController {
    
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
        
//        readingListNameTextView.delegate = self
//        descriptionTextView.delegate = self
//        readingListNameTextView.showsClearButton = true
//
//        readingListNameTextView.textView.returnKeyType = .next
//        readingListNameTextView.textView.enablesReturnKeyAutomatically = true
//        descriptionTextView.textView.returnKeyType = .done
//        descriptionTextView.textView.enablesReturnKeyAutomatically = true
        
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
}

//extension CreateReadingListViewController: ThemeableTextViewDelegate {
//
//    func textViewDidChange(_ textView: UITextView) {
//        createReadingListButton.isEnabled = !readingListNameTextView.textView.text.isEmpty
//    }
//
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        guard text != "\n" else {
//            if !descriptionTextView.textView.isFirstResponder {
//                readingListNameTextView.textView.resignFirstResponder()
//                descriptionTextView.textView.becomeFirstResponder()
//            } else if !readingListNameTextView.textView.text.isEmpty {
//                descriptionTextView.textView.resignFirstResponder()
//                perform(#selector(createReadingListButtonPressed))
//            }
//            return false
//        }
//        return true
//    }
//}

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
