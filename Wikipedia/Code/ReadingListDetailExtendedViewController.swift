protocol ReadingListDetailExtendedViewControllerDelegate: class {
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didEditName name: String)
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didEditDescription description: String?)

}

class ReadingListDetailExtendedViewController: UIViewController {
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var titleTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    @IBOutlet weak var updateButton: UIButton!
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
        apply(theme: theme)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        articleCountLabel.setFont(with: .systemBold, style: .footnote, traitCollection: traitCollection)
        titleTextField.font = UIFont.wmf_preferredFontForFontFamily(.systemHeavy, withTextStyle: .headline, compatibleWithTraitCollection: traitCollection)
        descriptionTextField.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    var articleCount: Int64 = 0
    
    var articleCountString: String {
        return String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount)
    }
    
    public func updateArticleCount(_ count: Int64) {
        articleCount = count
        articleCountLabel.text = articleCountString.uppercased()
    }
    
    public func setup(title: String?, description: String?, articleCount: Int64) {
        titleTextField.text = title
        descriptionTextField.text = description
        updateArticleCount(articleCount)
        updateButton.setTitle(String.localizedStringWithFormat(WMFLocalizedString("update-articles-button", value: "Update %1$@", comment: "Title of the button that updates articles in a list."), articleCountString), for: .normal)
    }
    
}
extension ReadingListDetailExtendedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, titleTextField.isFirstResponder {
            delegate?.extendedViewController(self, didEditName: text)
            titleTextField.resignFirstResponder()
            return true
        } else if descriptionTextField.isFirstResponder {
            delegate?.extendedViewController(self, didEditDescription: textField.text)
            descriptionTextField.resignFirstResponder()
            return true
        }
        return true
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
    }
}
