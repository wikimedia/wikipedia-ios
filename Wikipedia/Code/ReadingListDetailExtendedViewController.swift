protocol ReadingListDetailExtendedViewControllerDelegate: class {
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didEdit name: String?, description: String?)
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, searchTextDidChange searchText: String)
    func extendedViewControllerDidPressSortButton(_ extendedViewController: ReadingListDetailExtendedViewController)
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didBeginEditing textField: UITextField)
}

class ReadingListDetailExtendedViewController: UIViewController {
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var titleTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet var constraints: [NSLayoutConstraint] = []
    
    public weak var delegate: ReadingListDetailExtendedViewControllerDelegate?
    
    private var theme: Theme = Theme.standard
    
    public var isHidden: Bool = false {
        didSet {
            view.isHidden = isHidden
            isHidden ? NSLayoutConstraint.deactivate(constraints) : NSLayoutConstraint.activate(constraints)
        }
    }
    
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
        
        updateButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        updateButton.masksToBounds = true
        updateButton.cornerRadius = 18
        
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
        updateButton.titleLabel?.setFont(with: .systemSemiBold, style: .subheadline, traitCollection: traitCollection)
        sortButton.titleLabel?.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
    }
    
    // Int64 instead of Int to so that we don't have to cast countOfEntries: Int64 property of ReadingList object to Int.
    var articleCount: Int64 = 0 {
        didSet {
            guard viewIfLoaded != nil else {
                return
            }
            articleCountLabel.text = articleCountString.uppercased()
            updateButton.setTitle(String.localizedStringWithFormat(WMFLocalizedString("update-articles-button", value: "Update %1$@", comment: "Title of the button that updates articles in a list."), articleCountString), for: .normal)
        }
    }
    
    var articleCountString: String {
        return String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount)
    }
    
    public func updateArticleCount(_ count: Int64) {
        articleCount = count
    }
    
    public func setup(title: String?, description: String?, articleCount: Int64, isDefault: Bool) {
        titleTextField.text = title
        descriptionTextField.text = isDefault ? CommonStrings.readingListsDefaultListDescription : description
        titleTextField.isEnabled = !isDefault
        descriptionTextField.isEnabled = !isDefault
        updateArticleCount(articleCount)
    }
    
    @IBAction func didPressSortButton(_ sender: UIButton) {
        delegate?.extendedViewControllerDidPressSortButton(self)
    }
    
    public func cancelEditing() {
        
    }
    
    public func finishEditing() {
        
    }
    
}

extension ReadingListDetailExtendedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.extendedViewController(self, didEdit: titleTextField.text, description: descriptionTextField.text)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
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
        titleTextField.apply(theme: theme)
        descriptionTextField.apply(theme: theme)
        descriptionTextField.textColor = theme.colors.secondaryText
        updateButton.backgroundColor = theme.colors.accent
        updateButton.setTitleColor(theme.colors.paperBackground, for: .normal)
        separatorView.backgroundColor = theme.colors.border
    }
}
