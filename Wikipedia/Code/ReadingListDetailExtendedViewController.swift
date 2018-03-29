protocol ReadingListDetailExtendedViewControllerDelegate: class {
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didEdit name: String?, description: String?)
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, searchTextDidChange searchText: String)
    func extendedViewControllerDidPressSortButton(_ extendedViewController: ReadingListDetailExtendedViewController, sortButton: UIButton)
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didBeginEditing textField: UITextField)
}

class ReadingListDetailExtendedViewController: UIViewController {
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var titleTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var alertMessageLabel: UILabel!
    @IBOutlet var alertViewConstraints: [NSLayoutConstraint] = []
    private var descriptionTextFieldToSeparatorViewBottomConstraint: NSLayoutConstraint?
    
    private var readingListTitle: String?
    private var readingListDescription: String?
    
    private var listLimit: Int = 0
    private var entryLimit: Int = 0
    
    public weak var delegate: ReadingListDetailExtendedViewControllerDelegate?
    
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
        
        sortButton.setTitle(CommonStrings.sortActionTitle, for: .normal)
        
        searchBar.returnKeyType = .search
        searchBar.placeholder = WMFLocalizedString("search-reading-list-placeholder-text", value: "Search reading list", comment: "Placeholder text for the search bar in reading list detail view.")
        searchBar.delegate = self
        
        apply(theme: theme)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        articleCountLabel.setFont(with: .systemSemiBold, style: .footnote, traitCollection: traitCollection)
        titleTextField.font = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
        descriptionTextField.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
        sortButton.titleLabel?.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
        alertTitleLabel.setFont(with: .systemSemiBold, style: .caption2, traitCollection: traitCollection)
        alertMessageLabel.setFont(with: .system, style: .caption2, traitCollection: traitCollection)
    }
    
    // Int64 instead of Int to so that we don't have to cast countOfEntries: Int64 property of ReadingList object to Int.
    var articleCount: Int64 = 0 {
        didSet {
            guard viewIfLoaded != nil else {
                return
            }
            articleCountLabel.text = articleCountString.uppercased()
        }
    }
    
    var articleCountString: String {
        return String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount)
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
                let alertTitleFormat = WMFLocalizedString("reading-list-list-limit-exceeded-title", value: "You have exceeded the limit of %1$d reading lists per account.", comment: "Informs the user that they have reached the allowed limit of reading lists per account.")
                let alertMessageFormat = WMFLocalizedString("reading-list-list-limit-exceeded-message", value: "This reading list and the articles saved to it will not be synced, please decrease your number of lists to %1$d to resume syncing of this list.", comment: "Informs the user that the reading list and its articles will not be synced until the number of lists is decreased.")
                alertTitleLabel.text = String.localizedStringWithFormat(alertTitleFormat, limit)
                alertMessageLabel.text = String.localizedStringWithFormat(alertMessageFormat, limit)
            case .entryLimitExceeded(let limit):
                let alertTitleFormat = WMFLocalizedString("reading-list-entry-limit-exceeded-title", value: "You have exceeded the limit of %1$d articles per account.", comment: "Informs the user that they have reached the allowed limit of reading lists per account.")
                let alertMessageFormat = WMFLocalizedString("reading-list-entry-limit-exceeded-message", value: "Please decrease your number of articles in this list to %1$d to resume syncing of all articles in this list.", comment: "Informs the user that the reading list and its articles will not be synced until the number of lists is decreased.")
                alertTitleLabel.text = String.localizedStringWithFormat(alertTitleFormat, limit)
                alertMessageLabel.text = String.localizedStringWithFormat(alertMessageFormat, limit)
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
            collapseAlert(isAlertViewHidden)
        }
    }
    
    @IBAction func didPressSortButton(_ sender: UIButton) {
        delegate?.extendedViewControllerDidPressSortButton(self, sortButton: sender)
    }
    
    public func reconfigureAlert(for readingList: ReadingList) {
        setAlertType(for: readingList.APIError, listLimit: listLimit, entryLimit: entryLimit)
    }
    
    public func dismissKeyboardIfNecessary() {
        firstResponder?.resignFirstResponder()
    }
    
    public func cancelEditing() {
        titleTextField.text = readingListTitle
        descriptionTextField.text = readingListDescription
        dismissKeyboardIfNecessary()
    }
    
    public func finishEditing() {
        delegate?.extendedViewController(self, didEdit: titleTextField.text, description: descriptionTextField.text)
        dismissKeyboardIfNecessary()
    }
    
    public func collapseAlert(_ collapse: Bool) {
        if descriptionTextFieldToSeparatorViewBottomConstraint == nil {
            descriptionTextFieldToSeparatorViewBottomConstraint = descriptionTextField.bottomAnchor.constraint(equalTo: separatorView.topAnchor)
            self.descriptionTextFieldToSeparatorViewBottomConstraint?.constant = -15
        }
        if collapse {
            self.alertView.isHidden = true
            NSLayoutConstraint.deactivate(self.alertViewConstraints)
            self.descriptionTextFieldToSeparatorViewBottomConstraint?.isActive = true
        } else {
            self.alertView.isHidden = false
            self.descriptionTextFieldToSeparatorViewBottomConstraint?.isActive = false
            NSLayoutConstraint.activate(self.alertViewConstraints)
        }
    }
    
}

extension ReadingListDetailExtendedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        finishEditing()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
        delegate?.extendedViewController(self, didBeginEditing: textField)
    }
}

extension ReadingListDetailExtendedViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.extendedViewController(self, searchTextDidChange: searchText)
        
        if searchText.isEmpty {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension ReadingListDetailExtendedViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        articleCountLabel.textColor = theme.colors.secondaryText
        articleCountLabel.backgroundColor = view.backgroundColor
        titleTextField.apply(theme: theme)
        alertTitleLabel.backgroundColor = view.backgroundColor
        alertMessageLabel.backgroundColor = view.backgroundColor
        descriptionTextField.apply(theme: theme)
        descriptionTextField.textColor = theme.colors.secondaryText
        separatorView.backgroundColor = theme.colors.border
        alertTitleLabel.textColor = theme.colors.error
        alertMessageLabel.textColor = theme.colors.primaryText
    }
}
