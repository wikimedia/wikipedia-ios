
import UIKit

//TODO:
// - add "Try to keep descriptions short so users can understand the article's subject at a glance"
// - remove testing didReceiveMemoryWarning triggers here and in other VCs
// - toggle placeholder label visibility when description field empty? or instead just set its text to placeholder text, and if text is placeholder text make its color change AND make giving it focus clear the text?

class DescriptionEditViewController: WMFScrollViewController, Themeable, UITextViewDelegate {
    
    private var licenseLabelAttributedString: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-license", value: "By changing the title description, I agree to the %1$@ and to irrevocably release my contributions under the %2$@ license.", comment: "Button text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - 'Terms of Use' link, %2$@ - license name link")
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor : theme.colors.secondaryText,
            NSAttributedString.Key.font : licenseLabel.font // Grab font so we get font updated for current dynamic type size
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor : theme.colors.link
        ]
        return formatString.attributedString(attributes: baseAttributes, substitutionStrings: [Licenses.localizedSaveTermsTitle, Licenses.localizedCCZEROTitle], substitutionAttributes: [linkAttributes, linkAttributes])
    }
    
    @objc var article: WMFArticle? = nil

    private lazy var whiteSpaceNormalizationRegex: NSRegularExpression? = {
        guard let regex = try? NSRegularExpression(pattern: "\\s+", options: []) else {
            assertionFailure("Unexpected failure to create regex")
            return nil
        }
        return regex
    }()

    @IBAction func licenseTapped() {
        let sheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .alert)
        sheet.addAction(UIAlertAction.init(title: Licenses.localizedSaveTermsTitle, style: .default, handler: { _ in
            self.wmf_openExternalUrl(Licenses.saveTermsURL)
        }))
        sheet.addAction(UIAlertAction.init(title: Licenses.localizedCCZEROTitle, style: .default, handler: { _ in
            self.wmf_openExternalUrl(Licenses.CCZEROURL)
        }))
        sheet.addAction(UIAlertAction.init(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
override func didReceiveMemoryWarning() {
    guard view.superview != nil else {
        return
    }
    dismiss(animated: true, completion: nil)
}
    

    public func textViewDidChange(_ textView: UITextView) {
        guard let username = descriptionTextView.text else{
            enableProgressiveButton(false)
            return
        }
        if let text = descriptionTextView.text, let whiteSpaceNormalizationRegex = whiteSpaceNormalizationRegex {
            descriptionTextView.text = whiteSpaceNormalizationRegex.stringByReplacingMatches(in: text, options: [], range: NSMakeRange(0, text.count), withTemplate: " ")
        }
        enableProgressiveButton(username.count > 0)
    }

    @IBOutlet private var learnMoreButton: UIButton!
    @IBOutlet private var subTitleLabel: UILabel!
    @IBOutlet private var descriptionTextView: UITextView!
    @IBOutlet private var licenseLabel: UILabel!
    @IBOutlet private var divider: UIView!
    @IBOutlet private var cc0ImageView: UIImageView!
    @IBOutlet private var publishDescriptionButton: WMFAuthButton!
    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        // descriptionTextView.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        publishDescriptionButton.setTitle(WMFLocalizedString("description-edit-publish", value:"Publish description", comment:"Title for publish description button"), for: .normal)
        
        learnMoreButton.setTitle(WMFLocalizedString("description-edit-learn-more", value:"Learn more", comment:"Title text for description editing learn more button"), for: .normal)
        title = WMFLocalizedString("description-edit-title", value:"Edit description", comment:"Title text for description editing screen")

        view.wmf_configureSubviewsForDynamicType()
        apply(theme: theme)
        
        if let existingDescription = article?.wikidataDescription {
          descriptionTextView.text = existingDescription
        }
        
        descriptionTextView.textContainer.lineFragmentPadding = 0
    }
    
    private var titleDescriptionFor: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-for-article", value: "Title description for %1$@", comment: "String describing which article title description is being edited. %1$@ is replaced with the article title")
        return String.localizedStringWithFormat(formatString, article?.displayTitleHTML ?? "").byAttributingHTML(with: .subheadline, matching: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        subTitleLabel.attributedText = titleDescriptionFor
        licenseLabel.attributedText = licenseLabelAttributedString
    }
    
    @IBAction func showAboutWikidataPage() {
        wmf_openExternalUrl(URL(string: "https://m.wikidata.org/wiki/Wikidata:Introduction"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        descriptionTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }

    func enableProgressiveButton(_ highlight: Bool) {
        publishDescriptionButton.isEnabled = highlight
    }

    @IBAction private func publishDescriptionButton(withSender sender: UIButton) {
        save()
    }

    private func save() {
        wmf_hideKeyboard()
        
        // Final trim to remove leading and trailing space
        let descriptionToSave = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
print("'\(descriptionToSave)'")
// TODO: call new method to save `descriptionToSave` here - on success dismiss and show new `Description published` panel, on error show alert with server error msg
        
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        subTitleLabel.textColor = theme.colors.secondaryText
        cc0ImageView.tintColor = theme.colors.primaryText
        descriptionTextView.textColor = theme.colors.primaryText
        divider.backgroundColor = theme.colors.border
        publishDescriptionButton.apply(theme: theme)
    }
}
