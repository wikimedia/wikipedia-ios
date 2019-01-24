
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
    var wikiText = ""
    var funnel: EditFunnel?
    var savedPagesFunnel: SavedPagesFunnel?
    var theme: Theme = .standard
    weak var delegate: EditSaveViewControllerDelegate?

    var captchaViewController: WMFCaptchaViewController?
    @IBOutlet var captchaContainer: UIView!
    @IBOutlet var editSummaryVCContainer: UIView!
    @IBOutlet var captchaScrollView: UIScrollView!
    @IBOutlet var captchaScrollContainer: UIView!
    var borderWidth: CGFloat = 0.0
    @IBOutlet var previewLicenseView: PreviewLicenseView!
    var previewLicenseTapGestureRecognizer: UIGestureRecognizer?

    @IBOutlet var scrollContainer: UIView!
    var buttonSave: UIBarButtonItem?
    var buttonNext: UIBarButtonItem?
    var buttonX: UIBarButtonItem?
    var buttonLeftCaret: UIBarButtonItem?
    var abuseFilterCode = ""
    var summaryText = ""

    private var mode: NavigationMode = .preview {
        didSet {
            updateNavigation(for: mode)
        }
    }
    let wikiTextSectionUploader = WikiTextSectionUploader()
    
    private func updateNavigation(for mode: NavigationMode) {
        var backButton: UIBarButtonItem? = nil
        var forwardButton: UIBarButtonItem? = nil
        
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

    @objc func goBack() {
        if mode == .abuseFilterWarning {
            funnel?.logAbuseFilterWarningBack(abuseFilterCode)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func goForward() {
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
        summaryText = ""
        
        //self.saveAutomaticallyIfSignedIn = NO;
        
        funnel?.logPreview()
        
        borderWidth = 1.0 / UIScreen.main.scale

        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        captchaScrollView.alpha = 0.0
        
        captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
        captchaViewController?.captchaDelegate = self
        captchaViewController?.apply(theme: theme)
        wmf_add(childController: captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        mode = .preview
        
        let vc = EditSummaryViewController(nibName: EditSummaryViewController.wmf_classStoryboardName(), bundle: nil)
        vc.delegate = self
        wmf_add(childController: vc, andConstrainToEdgesOfContainerView: editSummaryVCContainer)
        vc.theme = theme
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
    
    @objc func licenseLabelTapped(_ recognizer: UIGestureRecognizer?) {
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
    
    func highlightCaptchaSubmitButton(_ highlight: Bool) {
        buttonSave?.isEnabled = highlight
    }

    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("TabularScrollViewItemTapped"), object: nil)
        
        previewLicenseView.licenseLoginLabel.removeGestureRecognizer(previewLicenseTapGestureRecognizer!)
        
        super.viewWillDisappear(animated)
    }

    func save() {
        
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
        
        wikiTextSectionUploader.uploadWikiText(self.wikiText, forArticleURL: editURL, section: "\(section.sectionId)", summary: self.summaryText, captchaId: self.captchaViewController?.captcha?.captchaID, captchaWord: self.captchaViewController?.solution, completion: { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleEditFailure(with: error)
                    return
                }
                if let result = result {
                    self.handleEditSuccess(with: result)
                } else {
                    self.handleEditFailure(with: NSError.wmf_error(with: WMFErrorType.unexpectedResponseType, userInfo: nil))
                }
            }
        })

    }
    
    func handleEditSuccess(with result: [AnyHashable: Any]) {
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
    
    func handleEditFailure(with error: Error) {
        let nsError = error as NSError
        let errorType = WikiTextSectionUploaderErrors.init(rawValue: nsError.code) ?? .WIKITEXT_UPLOAD_ERROR_UNKNOWN
        
        switch errorType {
        case .WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA:
            if mode == .captcha {
                funnel?.logCaptchaFailure()
            }
            
            let captchaUrl = URL(string: nsError.userInfo["captchaUrl"] as? String ?? "")
            let captchaId = nsError.userInfo["captchaId"] as? String ?? ""
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            captchaViewController?.captcha = WMFCaptcha(captchaID: captchaId, captchaURL: captchaUrl!)
            revealCaptcha()
            
        case .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED, .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING, .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER:
            //NSString *warningHtml = error.userInfo[@"warning"];
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            
            wmf_hideKeyboard()
            
            if (WikiTextSectionUploaderErrors.init(rawValue: nsError.code) == .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED) {
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
            
            let alertType: AbuseFilterAlertType = (WikiTextSectionUploaderErrors.init(rawValue: nsError.code) == .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED) ? .ABUSE_FILTER_DISALLOW : .ABUSE_FILTER_WARNING
            showAbuseFilterAlertOf(alertType)
            
        case .WIKITEXT_UPLOAD_ERROR_SERVER, .WIKITEXT_UPLOAD_ERROR_UNKNOWN:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            funnel?.logError("other")
        default:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            funnel?.logError("other")
        }
    }
    
    func showAbuseFilterAlertOf(_ alertType: AbuseFilterAlertType) {
        let abuseFilterAlert = AbuseFilterAlert(type: alertType)
        
        view.addSubview(abuseFilterAlert)
        
        let views = [
            "abuseFilterAlert": abuseFilterAlert
        ]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[abuseFilterAlert]|", options: [], metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[abuseFilterAlert]|", options: [], metrics: nil, views: views))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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

    func revealCaptcha() {
        funnel?.logCaptchaShown()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.35)
        UIView.setAnimationTransition(.none, for: view, cache: false)
        
        view.bringSubviewToFront(captchaScrollView)
        
        captchaScrollView.alpha = 1.0
        captchaScrollView.backgroundColor = theme.colors.paperBackground
        
        captchaScrollContainer.backgroundColor = UIColor.clear
        captchaContainer.backgroundColor = UIColor.clear
        
        UIView.commitAnimations()
        
        mode = .captcha
        
        highlightCaptchaSubmitButton(false)
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
        if viewIfLoaded == nil {
            return
        }
        scrollView.backgroundColor = theme.colors.paperBackground
        captchaScrollView.backgroundColor = theme.colors.baseBackground
        
        previewLicenseView.apply(theme: theme)
        
        scrollContainer.backgroundColor = theme.colors.paperBackground
        captchaContainer.backgroundColor = theme.colors.paperBackground
        captchaScrollContainer.backgroundColor = theme.colors.paperBackground
    }
    
    func learnMoreButtonTapped(sender: UIButton) {
        wmf_openExternalUrl(URL(string: "https://en.wikipedia.org/wiki/Help:Edit_summary"))
    }
    
    func summaryChanged(newSummary: String) {
        summaryText = newSummary
    }
    
    func cannedButtonTapped(type: EditSummaryViewCannedButtonType) {
        var eventLoggingKey = ""
        switch type {
        case .typo:
            eventLoggingKey = "typo"
        case .grammar:
            eventLoggingKey = "grammar"
        case .link:
            eventLoggingKey = "links"
        default:
            break
        }
        funnel?.logEditSummaryTap(eventLoggingKey)
    }
}
