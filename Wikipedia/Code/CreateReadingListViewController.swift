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
    
    weak var delegate: CreateReadingListDelegate?
    
    // Import shared reading list properties
    private let encodedPageIds: String?
    private let dataStore: MWKDataStore?
    
    var isInImportingMode: Bool {
        encodedPageIds != nil
    }
    
    // MARK: Lifecycle
    
    init(theme: Theme, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil, encodedPageIds: String? = nil, dataStore: MWKDataStore? = nil) {
        self.theme = theme
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        self.encodedPageIds = encodedPageIds
        self.dataStore = dataStore
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        if isInImportingMode {
            setupForImportingReadingList()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(false)
    }
    
// MARK: Public
    
    func handleReadingListNameError(_ error: ReadingListError) {
        readingListNameTextField.textColor = theme.colors.error
        readingListNameErrorLabel.isHidden = false
        readingListNameErrorLabel.text = error.localizedDescription
        createReadingListButton.isEnabled = false
    }
    
// MARK: Actions
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func createReadingListButtonPressed() {
        guard !isReadingListNameFieldEmpty, let trimmedName = readingListNameTextField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        let trimmedDescription = descriptionTextField.text?.trimmingCharacters(in: .whitespaces)
        delegate?.createReadingListViewController(self, didCreateReadingListWith: trimmedName, description: trimmedDescription, articles: articles)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }

// MARK: Private
    
    private func setupForImportingReadingList() {
        
        guard isInImportingMode else {
            return
        }
        
        self.title = WMFLocalizedString("import-shared-reading-list-title", value: "Import shared reading list", comment: "Title of screen that imports a shared reading list.")
        let closeButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonTapped(_:)))
        navigationItem.leftBarButtonItem = closeButton
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

// MARK: Themeable

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
