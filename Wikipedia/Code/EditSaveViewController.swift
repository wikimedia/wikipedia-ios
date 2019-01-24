
import UIKit
import WMF

protocol EditSaveViewControllerDelegate: NSObjectProtocol {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController)
}

@objc enum WMFPreviewAndSaveMode : Int {
    case PREVIEW_MODE_EDIT_WIKITEXT
    case PREVIEW_MODE_EDIT_WIKITEXT_WARNING
    case PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW
    case PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW
    case PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA
}

class EditSaveViewController: UIViewController, Themeable, FetchFinishedDelegate, UITextFieldDelegate, UIScrollViewDelegate, PreviewLicenseViewDelegate, WMFCaptchaViewControllerDelegate, EditSummaryViewDelegate {
    var section: MWKSection?
    var wikiText = ""
    var funnel: EditFunnel?
    var savedPagesFunnel: SavedPagesFunnel?
    var theme: Theme?
    weak var delegate: EditSaveViewControllerDelegate?

    var captchaViewController: WMFCaptchaViewController?
    @IBOutlet var captchaContainer: UIView!
    @IBOutlet var editSummaryVCContainer: UIView!
    @IBOutlet var captchaScrollView: UIScrollView!
    @IBOutlet var captchaScrollContainer: UIView!
    var borderWidth: CGFloat = 0.0
    @IBOutlet var previewLicenseView: PreviewLicenseView!
    var previewLicenseTapGestureRecognizer: UIGestureRecognizer?
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollContainer: UIView!
    var buttonSave: UIBarButtonItem?
    var buttonNext: UIBarButtonItem?
    var buttonX: UIBarButtonItem?
    var buttonLeftCaret: UIBarButtonItem?
    var abuseFilterCode = ""
    var summaryText = ""

    var mode: WMFPreviewAndSaveMode = .PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW {
        didSet {
            updateNavigation(for: mode)
        }
    }
    var wikiTextSectionUploader: WikiTextSectionUploader?
    var editTokenFetcher: WMFAuthTokenFetcher?

    func getSummary() -> String? {
        return summaryText
    }
    
    func updateNavigation(for mode: WMFPreviewAndSaveMode) {
        var backButton: UIBarButtonItem? = nil
        var forwardButton: UIBarButtonItem? = nil
        
        switch mode {
        case .PREVIEW_MODE_EDIT_WIKITEXT:
            backButton = buttonLeftCaret
            forwardButton = buttonNext
        case .PREVIEW_MODE_EDIT_WIKITEXT_WARNING:
            backButton = buttonLeftCaret
            forwardButton = buttonSave
        case .PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW:
            backButton = buttonLeftCaret
            forwardButton = nil
        case .PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW:
            backButton = buttonLeftCaret
            forwardButton = buttonSave
        case .PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA:
            backButton = buttonX
            forwardButton = buttonSave
        default:
            break
        }
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = forwardButton
    }

    @objc func goBack() {
        if mode == .PREVIEW_MODE_EDIT_WIKITEXT_WARNING {
            funnel?.logAbuseFilterWarningBack(abuseFilterCode)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func goForward() {
        switch mode {
        case .PREVIEW_MODE_EDIT_WIKITEXT_WARNING:
            save()
            funnel?.logAbuseFilterWarningIgnore(abuseFilterCode)
        case .PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA:
            save()
        default:
            save()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if theme == nil {
            theme = .standard
        }
        
        navigationItem.title = WMFLocalizedStringWithDefaultValue("wikitext-preview-save-changes-title", nil, nil, "Save your changes", "Title for edit preview screens")
        
        previewLicenseView.previewLicenseViewDelegate = self
        
        buttonX = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(self.goBack))
        
        buttonLeftCaret = UIBarButtonItem.wmf_buttonType(WMFButtonType.caretLeft, target: self, action: #selector(self.goBack))
        
        buttonSave = UIBarButtonItem(title: WMFLocalizedStringWithDefaultValue("button-publish", nil, nil, "Publish", "Button text for publish button used in various places.\n{{Identical|Publish}}"), style: .plain, target: self, action: #selector(self.goForward))
        
        mode = .PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW
        summaryText = ""
        
        //self.saveAutomaticallyIfSignedIn = NO;
        
        funnel?.logPreview()
        
        borderWidth = 1.0 / UIScreen.main.scale

        if let theme = theme {
            apply(theme: theme)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        captchaScrollView.alpha = 0.0
        
        captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
        captchaViewController?.captchaDelegate = self
        captchaViewController?.apply(theme: theme ?? .standard)
        wmf_add(childController: captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        mode = .PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW
        
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
            guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard(), let theme = theme else {
                assertionFailure("Expected view controller and theme")
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

    func fetchFinished(_ sender: Any!, fetchedData: Any!, status: FetchFinalStatus, error: Error!) {
        if (sender is WikiTextSectionUploader) {
            switch status {
            case .FETCH_FINAL_STATUS_SUCCEEDED:
                let notifyDelegate = {
                    dispatchOnMainQueue({
                        self.delegate?.editSaveViewControllerDidSave(self)
                    })
                }
                guard let fetchedData = fetchedData as? [String: Any], let newRevID = fetchedData["newrevid"] as? Int32 else {
                    assertionFailure("Could not extract rev id as Int")
                    notifyDelegate()
                    return
                }
                funnel?.logSavedRevision(newRevID)
                notifyDelegate()
            case .FETCH_FINAL_STATUS_CANCELLED:
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            case .FETCH_FINAL_STATUS_FAILED:
                
                let nsError = error as NSError
                let errorType = WikiTextSectionUploaderErrors.init(rawValue: nsError.code) ?? .WIKITEXT_UPLOAD_ERROR_UNKNOWN
                
                switch errorType {
                case .WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA:
                    if mode == .PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA {
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
                        mode = .PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW
                        abuseFilterCode = nsError.userInfo["code"] as! String
                        funnel?.logAbuseFilterError(abuseFilterCode)
                    } else {
                        mode = .PREVIEW_MODE_EDIT_WIKITEXT_WARNING
                        abuseFilterCode = nsError.userInfo["code"] as! String
                        funnel?.logAbuseFilterWarning(abuseFilterCode)
                    }
                    
                    // Hides the license panel. Needed if logged in and a disallow is triggered.
                    WMFAlertManager.sharedInstance.dismissAlert()
                    
                    let alertType: AbuseFilterAlertType = (WikiTextSectionUploaderErrors.init(rawValue: nsError.code) == .WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED) ? .ABUSE_FILTER_DISALLOW : .ABUSE_FILTER_WARNING
                    showAbuseFilterAlertOf(alertType)

                case .WIKITEXT_UPLOAD_ERROR_SERVER, .WIKITEXT_UPLOAD_ERROR_UNKNOWN:
                    WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                    funnel?.logError(error.localizedDescription) // @fixme is this right msg?
                default:
                    WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                }
            }
        }
    }

    func save() {
        
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedStringWithDefaultValue("wikitext-upload-save", nil, nil, "Publishing...", "Alert text shown when changes to section wikitext are being published\n{{Identical|Publishing}}"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        
        funnel?.logSaveAttempt()
        if (savedPagesFunnel != nil) {
            savedPagesFunnel?.logEditAttempt(withArticleURL: section?.article?.url)
        }

        
        QueuesSingleton.sharedInstance().sectionWikiTextUploadManager.wmf_cancelAllTasks(completionHandler: {
            
            guard let section = self.section else {
                assertionFailure("Could not get section to be edited")
                return
            }
            guard let editURL: URL = (section.fromURL != nil) ? section.fromURL : section.article?.url else {
                assertionFailure("Could not get url of section to be edited")
                return
            }
            guard let url: URL = SessionSingleton.sharedInstance().url(forLanguage: editURL.wmf_language) else {
                assertionFailure("Could not get siteURL")
                return
            }
            self.editTokenFetcher = WMFAuthTokenFetcher()
            //weakify(self)
            self.editTokenFetcher?.fetchToken(ofType: WMFAuthTokenType.csrf, siteURL: url, success: { result in
                //strongify(self)
                
                self.wikiTextSectionUploader = WikiTextSectionUploader.init(andUploadWikiText: self.wikiText, forArticleURL: editURL, section: "\(section.sectionId)", summary: self.getSummary(), captchaId: self.captchaViewController?.captcha?.captchaID, captchaWord: self.captchaViewController?.solution, token: result.token, with: QueuesSingleton.sharedInstance().sectionWikiTextUploadManager, thenNotify: self)
                
                
            }, failure: { error in
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            })
        })
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
        captchaScrollView.backgroundColor = theme?.colors.paperBackground
        
        captchaScrollContainer.backgroundColor = UIColor.clear
        captchaContainer.backgroundColor = UIColor.clear
        
        UIView.commitAnimations()
        
        mode = .PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA
        
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
