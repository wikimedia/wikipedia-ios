import UIKit

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createdNewReadingList(in controller: CreateReadingListViewController, with name: String, description: String?)
}

class CreateReadingListViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameTextView: ThemeableTextView!
    @IBOutlet weak var descriptionTextView: ThemeableTextView!
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        
        readingListNameTextView.textView.delegate = self
        descriptionTextView.textView.delegate = self
        
        readingListNameTextView.textView.returnKeyType = .next
        readingListNameTextView.textView.enablesReturnKeyAutomatically = true
        descriptionTextView.textView.returnKeyType = .done
        descriptionTextView.textView.enablesReturnKeyAutomatically = true
        
        readingListNameTextView.bringSubview(toFront: clearButton)
        
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
        guard let name = readingListNameTextView.textView.text else {
            return
        }
        delegate?.createdNewReadingList(in: self, with: name, description: descriptionTextView.textView.text)
    }
    
    @IBAction func clearButtonPressed() {
        readingListNameTextView.textView.text = ""
        updateClearButton()
    }
    
    fileprivate func updateClearButton() {
        clearButton.isHidden = readingListNameTextView.textView.text.isEmpty || !readingListNameTextView.textView.isFirstResponder
    }
}

extension CreateReadingListViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        createReadingListButton.isEnabled = !readingListNameTextView.textView.text.isEmpty
        updateClearButton()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text != "\n" else {
            if !descriptionTextView.textView.isFirstResponder {
                readingListNameTextView.textView.resignFirstResponder()
                descriptionTextView.textView.becomeFirstResponder()
            } else if !readingListNameTextView.textView.text.isEmpty {
                descriptionTextView.textView.resignFirstResponder()
                perform(#selector(createReadingListButtonPressed))
            }
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateClearButton()
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
        
        readingListNameTextView.apply(theme: theme)
        descriptionTextView.apply(theme: theme)
        
        titleLabel.textColor = theme.colors.primaryText
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        
        clearButton.tintColor = theme.colors.secondaryText
        
        createReadingListButton.apply(theme: theme)
       
    }
}
