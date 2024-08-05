import WMFComponents

protocol ReadingListDetailUnderBarViewControllerDelegate: AnyObject {
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didEdit name: String?, description: String?)
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didBeginEditing textField: UITextField)
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldTextDidChange textField: UITextField)
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldWillClear textField: UITextField)
}

class ReadingListDetailUnderBarViewController: UIViewController {
    @IBOutlet private weak var articleCountLabel: UILabel!
    @IBOutlet private weak var titleTextField: ThemeableTextField!
    @IBOutlet private weak var descriptionTextField: ThemeableTextField!
    @IBOutlet private weak var alertStackView: UIStackView?
    @IBOutlet private weak var alertTitleLabel: UILabel?
    @IBOutlet private weak var alertMessageLabel: UILabel?
    
    private var readingListTitle: String?
    private var readingListDescription: String?
    
    private var listLimit: Int = 0
    private var entryLimit: Int = 0
    
    public weak var delegate: ReadingListDetailUnderBarViewControllerDelegate?
    
    private var theme: Theme = Theme.standard
    
    private var firstResponder: UITextField? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.isUnderlined = false
        titleTextField.returnKeyType = .done
        titleTextField.enablesReturnKeyAutomatically = true
        descriptionTextField.isUnderlined = false
        descriptionTextField.returnKeyType = .done
        descriptionTextField.enablesReturnKeyAutomatically = true
        titleTextField.delegate = self
        descriptionTextField.delegate = self
        alertTitleLabel?.numberOfLines = 0
        alertMessageLabel?.numberOfLines = 0
        updateFonts()
        apply(theme: theme)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        articleCountLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        titleTextField.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
        descriptionTextField.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        alertTitleLabel?.font = WMFFont.for(.boldCaption1, compatibleWith: traitCollection)
        alertMessageLabel?.font = WMFFont.for(.caption1, compatibleWith: traitCollection)
    }
    
    // Int64 instead of Int to so that we don't have to cast countOfEntries: Int64 property of ReadingList object to Int.
    var articleCount: Int64 = 0 {
        didSet {
            guard viewIfLoaded != nil else {
                return
            }
            articleCountLabel.text = String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount).uppercased()
        }
    }
    
    public func updateArticleCount(_ count: Int64) {
        articleCount = count
    }
    
    private var alertType: ReadingListAlertType? {
        didSet {
            guard let alertType = alertType else {
                return
            }
            switch alertType {
            case .listLimitExceeded(let limit):
                let alertTitleFormat = WMFLocalizedString("reading-list-list-limit-exceeded-title", value: "You have exceeded the limit of {{PLURAL:%1$d|%1$d reading list|%1$d reading lists}} per account.", comment: "Informs the user that they have reached the allowed limit of reading lists per account. %1$d will be replaced with the maximum number of allowed lists")
                let alertMessageFormat = WMFLocalizedString("reading-list-list-limit-exceeded-message", value: "This reading list and the articles saved to it will not be synced, please decrease your number of lists to %1$d to resume syncing of this list.", comment: "Informs the user that the reading list and its articles will not be synced until the number of lists is decreased. %1$d will be replaced with the maximimum number of allowed lists.")
                alertTitleLabel?.text = String.localizedStringWithFormat(alertTitleFormat, limit)
                alertMessageLabel?.text = String.localizedStringWithFormat(alertMessageFormat, limit)
            case .entryLimitExceeded(let limit):
                let alertTitleFormat = WMFLocalizedString("reading-list-entry-limit-exceeded-title", value: "You have exceeded the limit of {{PLURAL:%1$d|%1$d article|%1$d articles}} per account.", comment: "Informs the user that they have reached the allowed limit of articles per account. %1$d will be replaced with the maximum number of allowed articles")
                let alertMessageFormat = WMFLocalizedString("reading-list-entry-limit-exceeded-message", value: "Please decrease your number of articles in this list to %1$d to resume syncing of all articles in this list.", comment: "Informs the user that the reading list and its articles will not be synced until the number of articles in the list is decreased. %1$d will be replaced with the maximum number of allowed articles in a list")
                alertTitleLabel?.text = String.localizedStringWithFormat(alertTitleFormat, limit)
                alertMessageLabel?.text = String.localizedStringWithFormat(alertMessageFormat, limit)
            default:
                break
            }
        }
    }
    
    public func setup(for readingList: ReadingList, listLimit: Int, entryLimit: Int) {
        self.listLimit = listLimit
        self.entryLimit = entryLimit
        
        let readingListName = readingList.name
        let readingListDescription = readingList.isDefault ? CommonStrings.readingListsDefaultListDescription : readingList.readingListDescription
        let isDefault = readingList.isDefault
        
        titleTextField.text = readingListName
        readingListTitle = readingListName
        descriptionTextField.text = readingListDescription
        self.readingListDescription = readingListDescription
        
        titleTextField.isEnabled = !isDefault
        descriptionTextField.isEnabled = !isDefault
        
        updateArticleCount(readingList.countOfEntries)
        
        setAlertType(for: readingList.APIError, listLimit: listLimit, entryLimit: entryLimit)
    }
    
    private func setAlertType(for error: APIReadingListError?, listLimit: Int, entryLimit: Int) {
        guard let error = error else {
            isAlertViewHidden = true
            return
        }
        switch error {
        case .listLimit:
            alertType = .listLimitExceeded(limit: listLimit)
            isAlertViewHidden = false
        case .entryLimit:
            alertType = .entryLimitExceeded(limit: entryLimit)
            isAlertViewHidden = false
        default:
            isAlertViewHidden = true
        }
    }
    
    private var isAlertViewHidden: Bool = true {
        didSet {
            alertStackView?.spacing = isAlertViewHidden ? 0 : 7
            alertStackView?.isHidden = isAlertViewHidden
        }
    }
    
    public func reconfigureAlert(for readingList: ReadingList) {
        setAlertType(for: readingList.APIError, listLimit: listLimit, entryLimit: entryLimit)
    }
    
    public func dismissKeyboardIfNecessary() {
        firstResponder?.resignFirstResponder()
    }
    
    public func beginEditing() {
        firstResponder = titleTextField
        titleTextField.becomeFirstResponder()
    }
    
    public func cancelEditing() {
        titleTextField.text = readingListTitle
        descriptionTextField.text = readingListDescription
        dismissKeyboardIfNecessary()
    }
    
    public func finishEditing() {
        delegate?.readingListDetailUnderBarViewController(self, didEdit: titleTextField.text, description: descriptionTextField.text)
        dismissKeyboardIfNecessary()
    }
    
    
    @IBAction func titleTextFieldTextDidChange(_ sender: UITextField) {
        delegate?.readingListDetailUnderBarViewController(self, titleTextFieldTextDidChange: sender)
    }
    
}

extension ReadingListDetailUnderBarViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        finishEditing()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
        delegate?.readingListDetailUnderBarViewController(self, didBeginEditing: textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            delegate?.readingListDetailUnderBarViewController(self, titleTextFieldWillClear: textField)
        }
        return true
    }
    
}

extension ReadingListDetailUnderBarViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        articleCountLabel.textColor = theme.colors.secondaryText
        articleCountLabel.backgroundColor = view.backgroundColor
        titleTextField.apply(theme: theme)
        alertTitleLabel?.backgroundColor = view.backgroundColor
        alertMessageLabel?.backgroundColor = view.backgroundColor
        descriptionTextField.apply(theme: theme)
        descriptionTextField.textColor = theme.colors.secondaryText
        alertTitleLabel?.textColor = theme.colors.error
        alertMessageLabel?.textColor = theme.colors.primaryText
    }
}
