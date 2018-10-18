
import UIKit

@objc protocol DescriptionEditViewControllerDelegate: NSObjectProtocol {
    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController)
}

class DescriptionEditViewController: WMFScrollViewController, Themeable, UITextViewDelegate {
    @IBOutlet private var learnMoreButton: UIButton!
    @IBOutlet private var subTitleLabel: UILabel!
    @IBOutlet private var descriptionTextView: UITextView!
    @IBOutlet private var descriptionPlaceholderLabel: UILabel!
    @IBOutlet private var licenseLabel: UILabel!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var divider: UIView!
    @IBOutlet private var cc0ImageView: UIImageView!
    @IBOutlet private var publishDescriptionButton: WMFAuthButton!
    @IBOutlet private var warningLabel: UILabel!
    @IBOutlet private var warningCharacterCountLabel: UILabel!
    private var theme = Theme.standard

    @objc var article: MWKArticle? = nil
    private let showWarningIfDescriptionLongerThanCount = 90

    @objc var delegate: DescriptionEditViewControllerDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        warningLabel.text = WMFLocalizedString("description-edit-warning", value:"Try to keep descriptions short so users can understand the article's subject at a glance", comment:"Title text for label reminding users to keep descriptions concise")
        publishDescriptionButton.setTitle(WMFLocalizedString("description-edit-publish", value:"Publish description", comment:"Title for publish description button"), for: .normal)
        
        learnMoreButton.setTitle(WMFLocalizedString("description-edit-learn-more", value:"Learn more", comment:"Title text for description editing learn more button"), for: .normal)
        
        descriptionPlaceholderLabel.text = WMFLocalizedString("description-edit-placeholder-title", value:"Short descriptions are best", comment:"Placeholder text shown inside description field until user taps on it")

        view.wmf_configureSubviewsForDynamicType()
        apply(theme: theme)
        
        if let existingDescription = article?.entityDescription {
            descriptionTextView.text = existingDescription
            title = WMFLocalizedString("description-edit-title", value:"Edit description", comment:"Title text for description editing screen")
        } else {
            title = WMFLocalizedString("description-add-title", value:"Add description", comment:"Title text for description addition screen")
        }
        
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = .zero
        
        isPlaceholderLabelHidden = shouldHidePlaceholder()
        updateWarningLabelsForDescriptionCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
        loginLabel.isHidden = WMFAuthenticationManager.sharedInstance.isLoggedIn
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        descriptionTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }

    private var isPlaceholderLabelHidden = true {
        didSet {
            descriptionPlaceholderLabel.isHidden = isPlaceholderLabelHidden
        }
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        isPlaceholderLabelHidden = shouldHidePlaceholder()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        isPlaceholderLabelHidden = shouldHidePlaceholder()
    }
    
    private func shouldHidePlaceholder() -> Bool {
        return descriptionTextView.nilTextSafeCount() > 0
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let range = Range(range, in: textView.text) else {
            return true
        }
        let newText = textView.text.replacingCharacters(in: range, with: text)
        isPlaceholderLabelHidden = newText.count > 0
        return true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        subTitleLabel.attributedText = subTitleLabelAttributedString
        licenseLabel.attributedText = licenseLabelAttributedString
        loginLabel.attributedText = loginLabelAttributedString
    }

    private var subTitleLabelAttributedString: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-for-article", value: "Title description for %1$@", comment: "String describing which article title description is being edited. %1$@ is replaced with the article title")
        return String.localizedStringWithFormat(formatString, article?.displaytitle ?? "").byAttributingHTML(with: .semiboldSubheadline, matching: traitCollection)
    }
    
    private func characterCountWarningString(for descriptionCharacterCount: Int) -> String? {
        return String.localizedStringWithFormat(WMFLocalizedString("description-edit-length-warning", value: "%1$@ / %2$@", comment: "Displayed to indicate how many description characters were entered. Separator can be customized depending on the language. %1$@ is replaced with the number of characters entered, %2$@ is replaced with the recommended maximum number of characters."), String(descriptionCharacterCount), String(showWarningIfDescriptionLongerThanCount))
    }
    
    private var licenseLabelAttributedString: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-license", value: "By changing the title description, I agree to the %1$@ and to irrevocably release my contributions under the %2$@ license.", comment: "Button text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - 'Terms of Use' link, %2$@ - license name link")
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : theme.colors.secondaryText,
            .font : licenseLabel.font // Grab font so we get font updated for current dynamic type size
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : theme.colors.link
        ]
        return formatString.attributedString(attributes: baseAttributes, substitutionStrings: [Licenses.localizedSaveTermsTitle, Licenses.localizedCCZEROTitle], substitutionAttributes: [linkAttributes, linkAttributes])
    }
    
    private var loginLabelAttributedString: NSAttributedString {
        let formatString = CommonStrings.editAttribution
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : theme.colors.secondaryText,
            .font : loginLabel.font // Grab font so we get font updated for current dynamic type size
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : theme.colors.link
        ]
        return formatString.attributedString(attributes: baseAttributes, substitutionStrings: [CommonStrings.editSignIn], substitutionAttributes: [linkAttributes])
    }
    
    @IBAction private func descriptionPlaceholderLabelTapped() {
        isPlaceholderLabelHidden = true
    }

    @IBAction func showAboutWikidataPage() {
        let vc = DescriptionHelpViewController.init(theme: theme)
        let navVC = WMFThemeableNavigationController.init(rootViewController: vc, theme: theme)
        present(navVC, animated: true, completion: nil)
    }
    
    @IBAction func licenseTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: Licenses.localizedSaveTermsTitle, style: .default, handler: { _ in
            self.wmf_openExternalUrl(Licenses.saveTermsURL)
        }))
        sheet.addAction(UIAlertAction(title: Licenses.localizedCCZEROTitle, style: .default, handler: { _ in
            self.wmf_openExternalUrl(Licenses.CCZEROURL)
        }))
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func loginTapped() {
        wmf_showLoginViewController(theme: theme)
    }

    @IBAction private func publishDescriptionButton(withSender sender: UIButton) {
        save()
    }

    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    private func enableProgressiveButton(_ highlight: Bool) {
        publishDescriptionButton.isEnabled = highlight
    }

    private func save() {
        enableProgressiveButton(false)
        wmf_hideKeyboard()
        
        // Final trim to remove leading and trailing space
        let descriptionToSave = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let article = article, let dataStore = article.dataStore, let articleURL = article.url else {
            enableProgressiveButton(true)
            assertionFailure("Expected article, datastore or article url not found")
            return
        }
        
        dataStore.wikidataDescriptionEditingController.publish(newWikidataDescription: descriptionToSave, from: article.descriptionSource, for: articleURL) {error in
            let presentingVC = self.presentingViewController
            DispatchQueue.main.async {
                self.enableProgressiveButton(true)
                guard let error = error else {
                    self.delegate?.descriptionEditViewControllerEditSucceeded(self)
                    self.dismiss(animated: true) {
                        presentingVC?.wmf_showDescriptionPublishedPanelViewController(theme: self.theme)
                    }
                    return
                }
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            }
        }
    }
    
    private func updateWarningLabelsForDescriptionCount() {
        warningCharacterCountLabel.text = characterCountWarningString(for: descriptionTextView.nilTextSafeCount())
        
        let isDescriptionLong = descriptionTextView.nilTextSafeCount() > showWarningIfDescriptionLongerThanCount
        warningLabel.isHidden = !isDescriptionLong
        warningCharacterCountLabel.textColor = isDescriptionLong ? theme.colors.descriptionWarning : theme.colors.secondaryText
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        guard let description = descriptionTextView.text else{
            enableProgressiveButton(false)
            return
        }
        descriptionTextView.normalizeWhitespace()
        enableProgressiveButton(description.count > 0)
        updateWarningLabelsForDescriptionCount()
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
        descriptionPlaceholderLabel.textColor = theme.colors.unselected
        warningLabel.textColor = theme.colors.descriptionWarning
        warningCharacterCountLabel.textColor = theme.colors.descriptionWarning
        publishDescriptionButton.apply(theme: theme)
    }
}

private var whiteSpaceNormalizationRegex: NSRegularExpression? = {
    guard let regex = try? NSRegularExpression(pattern: "\\s+", options: []) else {
        assertionFailure("Unexpected failure to create regex")
        return nil
    }
    return regex
}()

private extension UITextView {
    func nilTextSafeCount() -> Int {
        guard let text = text else {
            return 0
        }
        return text.count
    }

    func normalizeWhitespace() {
        if let text = text, let whiteSpaceNormalizationRegex = whiteSpaceNormalizationRegex {
            self.text = whiteSpaceNormalizationRegex.stringByReplacingMatches(in: text, options: [], range: NSMakeRange(0, text.count), withTemplate: " ")
        }
    }
}
