
import UIKit
import WMF

struct SectionEditorChanges {
    let newRevisionID: UInt64
}

protocol EditSaveViewControllerDelegate: NSObjectProtocol {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<SectionEditorChanges, Error>)
}

private enum NavigationMode : Int {
    case wikitext
    case abuseFilterWarning
    case abuseFilterDisallow
    case preview
    case captcha
}

class EditSaveViewController: WMFScrollViewController, Themeable, UITextFieldDelegate, UIScrollViewDelegate, WMFCaptchaViewControllerDelegate, EditSummaryViewDelegate {
    var sectionID: Int?
    var articleURL: URL?
    var language: String?
    var dataStore: MWKDataStore?
    
    var wikitext = ""
    var theme: Theme = .standard
    weak var delegate: EditSaveViewControllerDelegate?

    // MARK: Event logging
    var editFunnel: EditFunnel?
    var editFunnelSource: EditFunnelSource = .unknown
    var savedPagesFunnel: SavedPagesFunnel?
    var loggedEditActions: NSMutableSet?

    private lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    @IBOutlet private var captchaContainer: UIView!
    @IBOutlet private var editSummaryVCContainer: UIView!
    @IBOutlet private var licenseTitleTextView: UITextView!
    @IBOutlet private var licenseLoginTextView: UITextView!
    @IBOutlet private var textViews: [UITextView]!
    @IBOutlet private var dividerHeightConstraits: [NSLayoutConstraint]!
    @IBOutlet private var dividerViews: [UIView]!
    @IBOutlet private var spacerAboveBottomDividerHeightConstrait: NSLayoutConstraint!

    @IBOutlet public var minorEditLabel: UILabel!
    @IBOutlet public var minorEditButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet public var minorEditToggle: UISwitch!
    @IBOutlet public var addToWatchlistLabel: UILabel!
    @IBOutlet public var addToWatchlistButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet public var addToWatchlistToggle: UISwitch!

    @IBOutlet public var addToWatchlistStackView: UIStackView!
    
    @IBOutlet private var scrollContainer: UIView!
    private var buttonSave: UIBarButtonItem?
    private var buttonNext: UIBarButtonItem?
    private var buttonX: UIBarButtonItem?
    private var buttonLeftCaret: UIBarButtonItem?
    private var abuseFilterCode = ""
    private var summaryText = ""

    private var mode: NavigationMode = .preview {
        didSet {
            updateNavigation(for: mode)
        }
    }
    private let wikiTextSectionUploader = WikiTextSectionUploader()
    
    private func updateNavigation(for mode: NavigationMode) {
        var backButton: UIBarButtonItem?
        var forwardButton: UIBarButtonItem?
        
        switch mode {
        case .wikitext:
            backButton = buttonLeftCaret
            forwardButton = buttonNext
        case .abuseFilterWarning:
            backButton = buttonLeftCaret
            forwardButton = buttonSave
        case .abuseFilterDisallow:
            backButton = buttonLeftCaret
            forwardButton = nil
        case .preview:
            backButton = buttonLeftCaret
            forwardButton = buttonSave
        case .captcha:
            backButton = buttonX
            forwardButton = buttonSave
        }
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = forwardButton
    }

    @objc private func goBack() {
        if mode == .abuseFilterWarning {
            editFunnel?.logAbuseFilterWarningBackForSectionEdit(abuseFilterName: abuseFilterCode, source: editFunnelSource, language: language)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func goForward() {
        switch mode {
        case .abuseFilterWarning:
            save()
            editFunnel?.logAbuseFilterWarningIgnoreForSectionEdit(abuseFilterName: abuseFilterCode, source: editFunnelSource, language: language)
        case .captcha:
            save()
        default:
            save()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = WMFLocalizedString("wikitext-preview-save-changes-title", value: "Save changes", comment: "Title for edit preview screens")
        
        buttonX = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(self.goBack))
        
        buttonLeftCaret = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(self.goBack))
        
        buttonSave = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(self.goForward))
        buttonSave?.tintColor = theme.colors.link

        mode = .preview
        
        minorEditLabel.text = WMFLocalizedString("edit-minor-text", value: "This is a minor edit", comment: "Text for minor edit label")
        minorEditButton.setTitle(WMFLocalizedString("edit-minor-learn-more-text", value: "Learn more about minor edits", comment: "Text for minor edits learn more button"), for: .normal)

        addToWatchlistLabel.text = WMFLocalizedString("edit-watch-this-page-text", value: "Watch this page", comment: "Text for watch this page label")
        addToWatchlistButton.setTitle(WMFLocalizedString("edit-watch-list-learn-more-text", value: "Learn more about watch lists", comment: "Text for watch lists learn more button"), for: .normal)
        
        for dividerHeightContraint in dividerHeightConstraits {
            dividerHeightContraint.constant = 1.0 / UIScreen.main.scale
        }
        
        // TODO: show this once we figure out how to handle watchlists (T214749)
        addToWatchlistStackView.isHidden = true

        if let loggedEditActions = loggedEditActions, !loggedEditActions.contains(EditFunnel.Action.editSummaryShown) {
            editFunnel?.logSectionEditSummaryShown(source: editFunnelSource, language: language)
            loggedEditActions.add(EditFunnel.Action.editSummaryShown)
        }
        updateTextViews()
        apply(theme: theme)
    }

    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("wikitext-upload-save-terms-and-licenses", value: "By publishing changes, you agree to the %1$@Terms of Use%2$@, and you irrevocably agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ License and the %5$@GFDL%6$@. You agree that a hyperlink or URL is sufficient attribution under the Creative Commons license.", comment: "Text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.")
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption2, matching: traitCollection)
        
        return attributedString
    }

    private var licenseLoginTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("wikitext-upload-save-anonymously-or-login", value: "Edits will be attributed to the IP address of your device. If you %1$@Log in%2$@ you will have more privacy.", comment: "Text informing user of draw-backs of not signing in before saving wikitext. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting.")
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"#LOGIN_HREF\">", // "#LOGIN_HREF" ensures 'byAttributingHTML' doesn't strip the anchor. The entire text view uses a tap recognizer so the string itself is unimportant.
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption2, matching: traitCollection)
        
        return attributedString
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTextViews()
    }
    
    private func updateTextViews() {
        licenseTitleTextView.attributedText = licenseTitleTextViewAttributedString
        licenseLoginTextView.attributedText = licenseLoginTextViewAttributedString
        applyThemeToTextViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        captchaViewController?.captchaDelegate = self
        captchaViewController?.apply(theme: theme)
        wmf_add(childController: captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        mode = .preview
        
        let vc = EditSummaryViewController(nibName: EditSummaryViewController.wmf_classStoryboardName(), bundle: nil)
        vc.delegate = self
        vc.apply(theme: theme)
        wmf_add(childController: vc, andConstrainToEdgesOfContainerView: editSummaryVCContainer)
        
        if dataStore?.authenticationManager.isLoggedIn ?? false {
            licenseLoginTextView.isHidden = true
        }
        
        super.viewWillAppear(animated)
    }
    
    @IBAction public func licenseLoginLabelTapped(_ recognizer: UIGestureRecognizer?) {
        if recognizer?.state == .ended {
            guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
                assertionFailure("Expected view controller")
                return
            }
            loginVC.funnel = WMFLoginFunnel()
            loginVC.funnel?.logStart(fromEdit: editFunnel?.sessionToken)
            loginVC.apply(theme: theme)
            present(WMFThemeableNavigationController(rootViewController: loginVC, theme: theme), animated: true)
        }
    }
    
    private func highlightCaptchaSubmitButton(_ highlight: Bool) {
        buttonSave?.isEnabled = highlight
    }

    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }

    private func save() {
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("wikitext-upload-save", value: "Publishing...", comment: "Alert text shown when changes to section wikitext are being published {{Identical|Publishing}}"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)

        editFunnel?.logSectionSaveAttempt(source: editFunnelSource, language: language)

        if (savedPagesFunnel != nil) {
            savedPagesFunnel?.logEditAttempt(withArticleURL: articleURL)
        }
        
        guard let sectionID = sectionID else {
            assertionFailure("Could not get section to be edited")
            return
        }
        
        guard let editURL = articleURL else {
            assertionFailure("Could not get url of section to be edited")
            return
        }
        
        wikiTextSectionUploader.uploadWikiText(wikitext, forArticleURL: editURL, section: "\(sectionID)", summary: summaryText, isMinorEdit: minorEditToggle.isOn, addToWatchlist: addToWatchlistToggle.isOn, captchaId: captchaViewController?.captcha?.captchaID, captchaWord: captchaViewController?.solution, completion: { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleEditFailure(with: error)
                    return
                }
                if let result = result {
                    self.handleEditSuccess(with: result)
                } else {
                    self.handleEditFailure(with: RequestError.unexpectedResponse)
                }
            }
        })

    }
    
    private func handleEditSuccess(with result: [AnyHashable: Any]) {
        let notifyDelegate: (Result<SectionEditorChanges, Error>) -> Void = { result in
            DispatchQueue.main.async {
                self.delegate?.editSaveViewControllerDidSave(self, result: result)
            }
        }
        guard let fetchedData = result as? [String: Any], let newRevID = fetchedData["newrevid"] as? UInt64 else {
            assertionFailure("Could not extract rev id as Int")
            notifyDelegate(.failure(RequestError.unexpectedResponse))
            return
        }
        editFunnel?.logSectionSaved(source: editFunnelSource, revision: newRevID, language: language)
        notifyDelegate(.success(SectionEditorChanges(newRevisionID: newRevID)))
    }
    
    private func handleEditFailure(with error: Error) {
        let nsError = error as NSError
        let errorType = WikiTextSectionUploaderErrorType.init(rawValue: nsError.code) ?? .unknown
        
        switch errorType {
        case .needsCaptcha:
            if mode == .captcha {
                editFunnel?.logCaptchaFailedForSectionEdit(source: editFunnelSource, language: language)
            }
            
            let captchaUrl = URL(string: nsError.userInfo["captchaUrl"] as? String ?? "")
            let captchaId = nsError.userInfo["captchaId"] as? String ?? ""
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            captchaViewController?.captcha = WMFCaptcha(captchaID: captchaId, captchaURL: captchaUrl!)
            editFunnel?.logCaptchaShownForSectionEdit(source: editFunnelSource, language: language)
            mode = .captcha
            highlightCaptchaSubmitButton(false)
            dispatchOnMainQueueAfterDelayInSeconds(0.1) { // Prevents weird animation.
                self.captchaViewController?.captchaTextFieldBecomeFirstResponder()
            }
        case .abuseFilterDisallowed, .abuseFilterWarning, .abuseFilterOther:
            //NSString *warningHtml = error.userInfo[@"warning"];

            wmf_hideKeyboard()
            
            if (errorType == .abuseFilterDisallowed) {
                WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                mode = .abuseFilterDisallow
                abuseFilterCode = nsError.userInfo["code"] as! String
                editFunnel?.logAbuseFilterErrorForSectionEdit(abuseFilterName: abuseFilterCode, source: editFunnelSource, language: language)
            } else {
                WMFAlertManager.sharedInstance.showWarningAlert(nsError.localizedDescription, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                mode = .abuseFilterWarning
                abuseFilterCode = nsError.userInfo["code"] as! String
                editFunnel?.logAbuseFilterWarningForSectionEdit(abuseFilterName: abuseFilterCode, source: editFunnelSource, language: language)
            }
            
            let alertType: AbuseFilterAlertType = (errorType == .abuseFilterDisallowed) ? .disallow : .warning
            showAbuseFilterAlert(for: alertType)
            
        case .server, .unknown:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            editFunnel?.logSectionSaveError(source: editFunnelSource, language: language, errorText: "other")
        default:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            editFunnel?.logSectionSaveError(source: editFunnelSource, language: language, errorText: "other")
        }
    }
    
    private func showAbuseFilterAlert(for type: AbuseFilterAlertType) {
        if let abuseFilterAlertView = AbuseFilterAlertView.wmf_viewFromClassNib() {
            abuseFilterAlertView.type = type
            abuseFilterAlertView.apply(theme: theme)
            abuseFilterAlertView.isHidden = true
            view.wmf_addSubviewWithConstraintsToEdges(abuseFilterAlertView)
            dispatchOnMainQueueAfterDelayInSeconds(0.3) {
                abuseFilterAlertView.isHidden = false
            }
        }
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let solution = captchaViewController?.solution {
            if !solution.isEmpty {
                save()
            }
        }
        return true
    }
    
    func captchaSiteURL() -> URL {
        return articleURL?.wmf_site ?? Configuration.current.defaultSiteURL
    }

    func captchaReloadPushed(_ sender: AnyObject) {
    }
    
    func captchaHideSubtitle() -> Bool {
        return true
    }
    
    func captchaKeyboardReturnKeyTapped() {
        save()
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
        highlightCaptchaSubmitButton(((solutionText?.count ?? 0) == 0) ? false : true)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        scrollView.backgroundColor = theme.colors.paperBackground

        minorEditLabel.textColor = theme.colors.primaryText
        minorEditButton.titleLabel?.textColor = theme.colors.link
        addToWatchlistLabel.textColor = theme.colors.primaryText
        addToWatchlistButton.titleLabel?.textColor = theme.colors.link
        scrollContainer.backgroundColor = theme.colors.paperBackground
        captchaContainer.backgroundColor = theme.colors.paperBackground
        
        applyThemeToTextViews()
        
        for dividerView in dividerViews {
            dividerView.backgroundColor = theme.colors.tertiaryText
        }
    }
    
    private func applyThemeToTextViews() {
        for textView in textViews {
            textView.backgroundColor = theme.colors.paperBackground
            textView.textColor = theme.colors.secondaryText
            textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: theme.colors.link]
        }
    }
    
    func learnMoreButtonTapped(sender: UIButton) {
        navigate(to: URL(string: "https://en.wikipedia.org/wiki/Help:Edit_summary"))
    }

    @IBAction public func minorEditButtonTapped(sender: UIButton) {
        navigate(to: URL(string: "https://en.wikipedia.org/wiki/Help:Minor_edit"))
    }

    @IBAction public func watchlistButtonTapped(sender: UIButton) {
        navigate(to: URL(string: "https://en.wikipedia.org/wiki/Help:Watchlist"))
    }

    func summaryChanged(newSummary: String) {
        summaryText = newSummary
    }
    
    func cannedButtonTapped(type: EditSummaryViewCannedButtonType) {
        editFunnel?.logSectionEditSummaryTap(source: editFunnelSource, editSummaryType: type, language: language)
    }
    
    // Keep bottom divider and license/login labels at bottom of screen while remaining scrollable.
    // (Having these bits scrollable is important for landscape, being covered by keyboard, captcha appearance, small screen devices, etc.)
    private func adjustHeightOfSpacerAboveBottomDividerSoContentViewIsAtLeastHeightOfScrollView() {
        spacerAboveBottomDividerHeightConstrait.constant = 0
        scrollContainer.setNeedsLayout()
        scrollContainer.layoutIfNeeded()
        spacerAboveBottomDividerHeightConstrait.constant = max(0, scrollView.frame.size.height - scrollContainer.frame.size.height)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustHeightOfSpacerAboveBottomDividerSoContentViewIsAtLeastHeightOfScrollView()
    }
}
