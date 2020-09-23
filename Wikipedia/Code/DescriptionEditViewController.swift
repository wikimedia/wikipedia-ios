import UIKit
import WMF

@objc protocol DescriptionEditViewControllerDelegate: NSObjectProtocol {
    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController)
}

@objc class DescriptionEditViewController: WMFScrollViewController, Themeable, UITextViewDelegate {
    @objc public static let didPublishNotification = NSNotification.Name("DescriptionEditViewControllerDidPublishNotification")

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

    private let showWarningIfDescriptionLongerThanCount = 90

    @objc var delegate: DescriptionEditViewControllerDelegate? = nil

    // MARK: Event logging
    @objc var editFunnel: EditFunnel?
    @objc var editFunnelSource: EditFunnelSource = .unknown
    
    // These would be better as let's and a required initializer but it's not an opportune time to ditch the storyboard
    // Convert these to non-force unwrapped if there's some way to ditch the storyboard or provide an initializer with the storyboard
    var article: WMFArticle!
    var wikidataID: String!
    var articleURL: URL!
    var descriptionSource: ArticleDescriptionSource!
    var isAddingNewTitleDescription: Bool!
    var dataStore: MWKDataStore!
    static func with(articleURL: URL, wikidataID: String, article: WMFArticle, descriptionSource: ArticleDescriptionSource, dataStore: MWKDataStore, theme: Theme) -> DescriptionEditViewController {
        let vc = wmf_initialViewControllerFromClassStoryboard()!
        vc.articleURL = articleURL
        vc.article = article
        vc.wikidataID = wikidataID
        vc.descriptionSource = descriptionSource
        vc.isAddingNewTitleDescription = descriptionSource == .none
        vc.dataStore = dataStore
        return vc
    }
    
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
        
        if let existingDescription = article.wikidataDescription {
            descriptionTextView.text = existingDescription
            title = WMFLocalizedString("description-edit-title", value:"Edit description", comment:"Title text for description editing screen")
        } else {
            title = WMFLocalizedString("description-add-title", value:"Add description", comment:"Title text for description addition screen")
        }
        
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = .zero
        
        isPlaceholderLabelHidden = shouldHidePlaceholder()
        updateWarningLabelsForDescriptionCount()
        updateFonts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
        loginLabel.isHidden = dataStore.authenticationManager.isLoggedIn
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
        isPlaceholderLabelHidden = !newText.isEmpty
        return true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        subTitleLabel.attributedText = subTitleLabelAttributedString
        licenseLabel.attributedText = licenseLabelAttributedString
        loginLabel.attributedText = loginLabelAttributedString
    }

    private var subTitleLabelAttributedString: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-for-article", value: "Title description for %1$@", comment: "String describing which article title description is being edited. %1$@ is replaced with the article title")
        return String.localizedStringWithFormat(formatString, article.displayTitle ?? "").byAttributingHTML(with: .semiboldSubheadline, matching: traitCollection)
    }
    
    private func characterCountWarningString(for descriptionCharacterCount: Int) -> String? {
        return String.localizedStringWithFormat(WMFLocalizedString("description-edit-length-warning", value: "%1$@ / %2$@", comment: "Displayed to indicate how many description characters were entered. Separator can be customized depending on the language. %1$@ is replaced with the number of characters entered, %2$@ is replaced with the recommended maximum number of characters."), String(descriptionCharacterCount), String(showWarningIfDescriptionLongerThanCount))
    }
    
    private var licenseLabelAttributedString: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-license", value: "By changing the title description, I agree to the %1$@ and to irrevocably release my contributions under the %2$@ license.", comment: "Button text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - 'Terms of Use' link, %2$@ - license name link")
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : theme.colors.secondaryText,
            .font : licenseLabel.font as Any // Grab font so we get font updated for current dynamic type size
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
            .font : loginLabel.font as Any // Grab font so we get font updated for current dynamic type size
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
            self.navigate(to: Licenses.saveTermsURL)
        }))
        sheet.addAction(UIAlertAction(title: Licenses.localizedCCZEROTitle, style: .default, handler: { _ in
            self.navigate(to: Licenses.CCZEROURL)
        }))
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func loginTapped() {
        wmf_showLoginViewController(theme: theme)
    }

    @IBAction private func publishDescriptionButton(withSender sender: UIButton) {
        editFunnel?.logTitleDescriptionSaveAttempt(source: editFunnelSource, isAddingNewTitleDescription: isAddingNewTitleDescription, language: articleURL.wmf_language)
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
        
        guard let language = articleURL.wmf_language else {
            enableProgressiveButton(true)
            assertionFailure("Expected article, datastore or article url not found")
            return
        }

        guard
            let descriptionToSave = descriptionTextView.normalizedWhitespaceText(),
            !descriptionToSave.isEmpty
            else {
                descriptionTextView.text = nil
                // manually call `textViewDidChange` since it's not called when UITextView text is changed programmatically
                textViewDidChange(descriptionTextView)
                return
        }
        
        dataStore.wikidataDescriptionEditingController.publish(newWikidataDescription: descriptionToSave, from: descriptionSource, forWikidataID: wikidataID, language: language) { error in
            DispatchQueue.main.async {
                let presentingVC = self.presentingViewController
                self.enableProgressiveButton(true)
                if let error = error {
                    let apiErrorCode = (error as? WikidataAPIResult.APIError)?.code
                    let errorText = apiErrorCode ?? "\((error as NSError).domain)-\((error as NSError).code)"
                    self.editFunnel?.logTitleDescriptionSaveError(source: self.editFunnelSource, isAddingNewTitleDescription: self.isAddingNewTitleDescription, language: self.articleURL.wmf_language, errorText: errorText)
                    WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                } else {
                    self.editFunnel?.logTitleDescriptionSaved(source: self.editFunnelSource, isAddingNewTitleDescription: self.isAddingNewTitleDescription, language: self.articleURL.wmf_language)
                    self.delegate?.descriptionEditViewControllerEditSucceeded(self)
                    self.dismiss(animated: true) {
                        presentingVC?.wmf_showDescriptionPublishedPanelViewController(theme: self.theme)
                        NotificationCenter.default.post(name: DescriptionEditViewController.didPublishNotification, object: nil)
                    }
                    return
                }
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
        let hasText = !descriptionTextView.text.isEmpty
        enableProgressiveButton(hasText)
        updateWarningLabelsForDescriptionCount()
        isPlaceholderLabelHidden = hasText
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.midBackground
        view.tintColor = theme.colors.link
        subTitleLabel.textColor = theme.colors.secondaryText
        cc0ImageView.tintColor = theme.colors.primaryText
        descriptionTextView.textColor = theme.colors.primaryText
        divider.backgroundColor = theme.colors.border
        descriptionPlaceholderLabel.textColor = theme.colors.unselected
        warningLabel.textColor = theme.colors.descriptionWarning
        warningCharacterCountLabel.textColor = theme.colors.descriptionWarning
        publishDescriptionButton.apply(theme: theme)
        descriptionTextView.keyboardAppearance = theme.keyboardAppearance
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

    // Text with no leading and trailing space and with repeating internal spaces reduced to single spaces
    func normalizedWhitespaceText() -> String? {
        if let text = text, let whiteSpaceNormalizationRegex = whiteSpaceNormalizationRegex {
            return whiteSpaceNormalizationRegex.stringByReplacingMatches(in: text, options: [], range: text.fullRange, withTemplate: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}
