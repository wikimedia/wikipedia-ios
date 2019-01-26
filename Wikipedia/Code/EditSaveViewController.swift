
import UIKit
import WMF

protocol EditSaveViewControllerDelegate: NSObjectProtocol {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController)
}

private enum NavigationMode : Int {
    case wikitext
    case abuseFilterWarning
    case abuseFilterDisallow
    case preview
    case captcha
}

class EditSaveViewController: WMFScrollViewController, Themeable, UITextFieldDelegate, UIScrollViewDelegate, PreviewLicenseViewDelegate, WMFCaptchaViewControllerDelegate, EditSummaryViewDelegate {
    var section: MWKSection?
    var wikitext = ""
    var funnel: EditFunnel?
    var savedPagesFunnel: SavedPagesFunnel?
    var theme: Theme = .standard
    weak var delegate: EditSaveViewControllerDelegate?

    private lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    @IBOutlet private var captchaContainer: UIView!
    @IBOutlet private var editSummaryVCContainer: UIView!
    private var borderWidth: CGFloat = 0.0
    @IBOutlet private var previewLicenseView: PreviewLicenseView!
    @IBOutlet private var minorEditOptionView: EditOptionView!
    @IBOutlet private var watchlistOptionView: EditOptionView!
    private var previewLicenseTapGestureRecognizer: UIGestureRecognizer?

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
            funnel?.logAbuseFilterWarningBack(abuseFilterCode)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func goForward() {
        switch mode {
        case .abuseFilterWarning:
            save()
            funnel?.logAbuseFilterWarningIgnore(abuseFilterCode)
        case .captcha:
            save()
        default:
            save()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = WMFLocalizedStringWithDefaultValue("wikitext-preview-save-changes-title", nil, nil, "Save your changes", "Title for edit preview screens")
        
        previewLicenseView.previewLicenseViewDelegate = self
        
        buttonX = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(self.goBack))
        
        buttonLeftCaret = UIBarButtonItem.wmf_buttonType(WMFButtonType.caretLeft, target: self, action: #selector(self.goBack))
        
        buttonSave = UIBarButtonItem(title: WMFLocalizedStringWithDefaultValue("button-publish", nil, nil, "Publish", "Button text for publish button used in various places.\n{{Identical|Publish}}"), style: .plain, target: self, action: #selector(self.goForward))
        
        mode = .preview
        
        //self.saveAutomaticallyIfSignedIn = NO;
        
        funnel?.logPreview()
        
        borderWidth = 1.0 / UIScreen.main.scale

        minorEditOptionView.label.text = WMFLocalizedStringWithDefaultValue("edit-minor-text", nil, nil, "This is a minor edit", "Text for minor edit label")
        minorEditOptionView.button.setTitle(WMFLocalizedStringWithDefaultValue("edit-minor-learn-more-text", nil, nil, "Learn more about minor edits", "Text for minor edits learn more button"), for: .normal)

        watchlistOptionView.label.text = WMFLocalizedStringWithDefaultValue("edit-watch-this-page-text", nil, nil, "Watch this page", "Text for watch this page label")
        watchlistOptionView.button.setTitle(WMFLocalizedStringWithDefaultValue("edit-watch-list-learn-more-text", nil, nil, "Learn more about watch lists", "Text for watch lists learn more button"), for: .normal)

        apply(theme: theme)
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
        //[self wmf_addChildControllerFromNibFor:[EditSummaryViewController class] andConstrainToEdgesOfContainerView:self.editSummaryVCContainer];
        //[self saveAutomaticallyIfNecessary];
        
        if WMFAuthenticationManager.sharedInstance.isLoggedIn {
            previewLicenseView.licenseLoginLabel.isUserInteractionEnabled = false
            previewLicenseView.licenseLoginLabel.attributedText = nil
        } else {
            previewLicenseView.licenseLoginLabel.isUserInteractionEnabled = true
        }
        
        previewLicenseTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.licenseLabelTapped(_:)))
        previewLicenseView.licenseLoginLabel.addGestureRecognizer(previewLicenseTapGestureRecognizer!)
        
        super.viewWillAppear(animated)
    }
    
    @objc private func licenseLabelTapped(_ recognizer: UIGestureRecognizer?) {
        if recognizer?.state == .ended {
            // Call if user taps the blue "Log In" text in the CC text.
            //self.saveAutomaticallyIfSignedIn = YES;
            guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
                assertionFailure("Expected view controller")
                return
            }
            loginVC.funnel = WMFLoginFunnel()
            loginVC.funnel?.logStart(fromEdit: funnel?.editSessionToken)
            loginVC.apply(theme: theme)
            present(WMFThemeableNavigationController(rootViewController: loginVC, theme: theme), animated: true)
        }
    }
    
    private func highlightCaptchaSubmitButton(_ highlight: Bool) {
        buttonSave?.isEnabled = highlight
    }

    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        previewLicenseView.licenseLoginLabel.removeGestureRecognizer(previewLicenseTapGestureRecognizer!)
        
        super.viewWillDisappear(animated)
    }

    private func save() {
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedStringWithDefaultValue("wikitext-upload-save", nil, nil, "Publishing...", "Alert text shown when changes to section wikitext are being published\n{{Identical|Publishing}}"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        
        funnel?.logSaveAttempt()
        
        if (savedPagesFunnel != nil) {
            savedPagesFunnel?.logEditAttempt(withArticleURL: section?.article?.url)
        }
        
        guard let section = self.section else {
            assertionFailure("Could not get section to be edited")
            return
        }
        
        guard let editURL: URL = (section.fromURL != nil) ? section.fromURL : section.article?.url else {
            assertionFailure("Could not get url of section to be edited")
            return
        }
        
        wikiTextSectionUploader.uploadWikiText(self.wikitext, forArticleURL: editURL, section: "\(section.sectionId)", summary: self.summaryText, captchaId: self.captchaViewController?.captcha?.captchaID, captchaWord: self.captchaViewController?.solution, completion: { (result, error) in
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
        let notifyDelegate = {
            DispatchQueue.main.async {
                self.delegate?.editSaveViewControllerDidSave(self)
            }
        }
        guard let fetchedData = result as? [String: Any], let newRevID = fetchedData["newrevid"] as? Int32 else {
            assertionFailure("Could not extract rev id as Int")
            notifyDelegate()
            return
        }
        funnel?.logSavedRevision(newRevID)
        notifyDelegate()
    }
    
    private func handleEditFailure(with error: Error) {
        let nsError = error as NSError
        let errorType = WikiTextSectionUploaderErrorType.init(rawValue: nsError.code) ?? .unknown
        
        switch errorType {
        case .needsCaptcha:
            if mode == .captcha {
                funnel?.logCaptchaFailure()
            }
            
            let captchaUrl = URL(string: nsError.userInfo["captchaUrl"] as? String ?? "")
            let captchaId = nsError.userInfo["captchaId"] as? String ?? ""
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            captchaViewController?.captcha = WMFCaptcha(captchaID: captchaId, captchaURL: captchaUrl!)
            funnel?.logCaptchaShown()
            mode = .captcha
            highlightCaptchaSubmitButton(false)
            dispatchOnMainQueueAfterDelayInSeconds(0.3) {
                self.captchaViewController?.captchaTextFieldBecomeFirstResponder()
            }

        case .abuseFilterDisallowed, .abuseFilterWarning, .abuseFilterOther:
            //NSString *warningHtml = error.userInfo[@"warning"];
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            
            wmf_hideKeyboard()
            
            if (errorType == .abuseFilterDisallowed) {
                mode = .abuseFilterDisallow
                abuseFilterCode = nsError.userInfo["code"] as! String
                funnel?.logAbuseFilterError(abuseFilterCode)
            } else {
                mode = .abuseFilterWarning
                abuseFilterCode = nsError.userInfo["code"] as! String
                funnel?.logAbuseFilterWarning(abuseFilterCode)
            }
            
            // Hides the license panel. Needed if logged in and a disallow is triggered.
            WMFAlertManager.sharedInstance.dismissAlert()
            
            let alertType: AbuseFilterAlertType = (errorType == .abuseFilterDisallowed) ? .disallow : .warning
            showAbuseFilterAlert(for: alertType)
            
        case .server, .unknown:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            funnel?.logError("other")
        default:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            funnel?.logError("other")
        }
    }
    
    private func showAbuseFilterAlert(for type: AbuseFilterAlertType) {
        if let abuseFilterAlertView = AbuseFilterAlertView.wmf_viewFromClassNib() {
            abuseFilterAlertView.type = type
            abuseFilterAlertView.apply(theme: theme)
            view.wmf_addSubviewWithConstraintsToEdges(abuseFilterAlertView)
        }
    }
    
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let solution = captchaViewController?.solution {
            if solution.count > 0 {
                save()
            }
        }
        return true
    }
    
    func captchaSiteURL() -> URL {
        return SessionSingleton.sharedInstance().currentArticleSiteURL
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
    
    func previewLicenseViewTermsLicenseLabelWasTapped(_ previewLicenseview: PreviewLicenseView?) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: Licenses.localizedSaveTermsTitle, style: .default, handler: { action in
            self.wmf_openExternalUrl(Licenses.saveTermsURL)
        }))
        sheet.addAction(UIAlertAction(title: Licenses.localizedCCBYSA3Title, style: .default, handler: { action in
            self.wmf_openExternalUrl(Licenses.CCBYSA3URL)
        }))
        sheet.addAction(UIAlertAction(title: Licenses.localizedGFDLTitle, style: .default, handler: { action in
            self.wmf_openExternalUrl(Licenses.GFDLURL)
        }))
        sheet.addAction(UIAlertAction(title: WMFLocalizedStringWithDefaultValue("open-link-cancel", nil, nil, "Cancel", "Text for cancel button in popup menu of terms/license link options\n{{Identical|Cancel}}"), style: .cancel, handler: nil))
        present(sheet, animated: true)
    
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        scrollView.backgroundColor = theme.colors.paperBackground
        previewLicenseView.apply(theme: theme)
        minorEditOptionView.apply(theme: theme)
        watchlistOptionView.apply(theme: theme)
        scrollContainer.backgroundColor = theme.colors.paperBackground
        captchaContainer.backgroundColor = theme.colors.paperBackground
    }
    
    func learnMoreButtonTapped(sender: UIButton) {
        wmf_openExternalUrl(URL(string: "https://en.wikipedia.org/wiki/Help:Edit_summary"))
    }
    
    func summaryChanged(newSummary: String) {
        summaryText = newSummary
    }
    
    func cannedButtonTapped(type: EditSummaryViewCannedButtonType) {
        funnel?.logEditSummaryTap(type.eventLoggingKey)
    }
}
