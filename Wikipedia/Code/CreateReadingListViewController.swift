import UIKit

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createReadingListViewController(_ createReadingListViewController: CreateReadingListViewController, didCreateReadingListWith name: String, description: String?, articles: [WMFArticle])
}

class CreateReadingListViewController: WMFScrollViewController, UITextFieldDelegate {
        
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameErrorLabel: UILabel!
    @IBOutlet weak var readingListNameTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    fileprivate let articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        readingListNameTextField.delegate = self
        descriptionTextField.delegate = self
        descriptionTextField.returnKeyType = .next
        readingListNameTextField.returnKeyType = .next
        readingListNameTextField.enablesReturnKeyAutomatically = true
        
        navigationItem.title = CommonStrings.createNewListTitle
        readingListNameLabel.text = WMFLocalizedString("reading-list-create-new-list-reading-list-name", value: "Reading list name", comment: "Title for label above text field for entering new list name.")
        descriptionLabel.text = WMFLocalizedString("reading-list-create-new-list-description", value: "Description", comment: "Title for label above text field for entering new list description.")
        readingListNameTextField.placeholder = WMFLocalizedString("reading-list-new-list-name-placeholder", value: "reading list title", comment: "Placeholder text appearing in text field for entering new list name")
        descriptionTextField.placeholder = WMFLocalizedString("reading-list-new-list-description-placeholder", value: "optional short description", comment: "Placeholder text appearing in text field for entering new list description")
        createReadingListButton.setTitle(WMFLocalizedString("reading-list-create-new-list-button-title", value: "Create reading list", comment: "Title for button allowing the user to create a new reading list."), for: .normal)
        
        createReadingListButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(false)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
    
    init(theme: Theme, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil) {
        self.theme = theme
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: CreateReadingListDelegate?
    
    @IBAction func createReadingListButtonPressed() {
        guard !isReadingListNameFieldEmpty, let trimmedName = readingListNameTextField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        let trimmedDescription = descriptionTextField.text?.trimmingCharacters(in: .whitespaces)
        delegate?.createReadingListViewController(self, didCreateReadingListWith: trimmedName, description: trimmedDescription, articles: articles)
    }
    
    func handleReadingListNameError(_ error: ReadingListError) {
        readingListNameTextField.textColor = theme.colors.error
        readingListNameErrorLabel.isHidden = false
        readingListNameErrorLabel.text = error.localizedDescription
        createReadingListButton.isEnabled = false
    }
    
    private func hideReadingListError() {
        guard !readingListNameErrorLabel.isHidden else {
            return
        }
        readingListNameErrorLabel.isHidden = true
        readingListNameTextField.textColor = theme.colors.primaryText
    }
    
    private var shouldEnableCreateReadingListButton: Bool {
        return (!isReadingListNameFieldEmpty && readingListNameTextField.isFirstResponder) && readingListNameErrorLabel.isHidden
    }
    
    // MARK: - UITextFieldDelegate
    
    fileprivate var isReadingListNameFieldEmpty: Bool {
        return !readingListNameTextField.wmf_hasNonWhitespaceText
    }
    
    fileprivate var isDescriptionFieldEmpty: Bool {
        return !descriptionTextField.wmf_hasNonWhitespaceText
    }
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        if readingListNameTextField.isFirstResponder {
            hideReadingListError()
        }
        createReadingListButton.isEnabled = !isReadingListNameFieldEmpty && readingListNameErrorLabel.isHidden
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readingListNameTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard !descriptionTextField.isFirstResponder else {
            readingListNameTextField.becomeFirstResponder()
            return true
        }
        if readingListNameTextField.isFirstResponder {
            descriptionTextField.becomeFirstResponder()
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if readingListNameTextField.isFirstResponder {
            hideReadingListError()
        }
        createReadingListButton.isEnabled = !isReadingListNameFieldEmpty && !readingListNameTextField.isFirstResponder && readingListNameErrorLabel.isHidden
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
        
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        readingListNameErrorLabel.textColor = theme.colors.error
        
        createReadingListButton.apply(theme: theme)
       
    }
}
