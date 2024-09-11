import SwiftUI
import WMF
import WMFComponents
import WMFData

struct EditorChanges {
    let newRevisionID: UInt64
    let fullArticleWikitextForAltTextExperiment: String?
}

protocol EditSaveViewControllerDelegate: NSObjectProtocol {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<EditorChanges, Error>)
    func editSaveViewControllerWillCancel(_ saveData: EditSaveViewController.SaveData)
    func editSaveViewControllerDidTapShowWebPreview()
}

protocol EditSaveViewControllerEditorLoggingDelegate: AnyObject {
    func logEditSaveViewControllerDidTapShowWebPreview()
    func logEditSaveViewControllerDidTapPublish(source: EditorViewController.Source, summaryAdded: Bool, isMinor: Bool, isWatched: Bool, project: WikimediaProject)
    func logEditSaveViewControllerPublishSuccess(source: EditorViewController.Source, revisionID: UInt64, project: WikimediaProject)
    func logEditSaveViewControllerPublishFailed(source: EditorViewController.Source, problemSource: EditInteractionFunnel.ProblemSource?, project: WikimediaProject)
    func logEditSaveViewControllerDidTapBlockedMessageLink(source: EditorViewController.Source, project: WikimediaProject)
}

protocol EditSaveViewControllerImageRecLoggingDelegate: AnyObject {
    func logEditSaveViewControllerDidAppear()
    func logEditSaveViewControllerDidTapBack()
    func logEditSaveViewControllerDidTapMinorEditsLearnMore()
    func logEditSaveViewControllerDidTapWatchlistLearnMore()
    func logEditSaveViewControllerDidToggleWatchlist(isOn: Bool)
    func logEditSaveViewControllerDidTapPublish(minorEditEnabled: Bool, watchlistEnabled: Bool)
    func logEditSaveViewControllerPublishSuccess(revisionID: Int, summaryAdded: Bool)
    func logEditSaveViewControllerLogPublishFailed(abortSource: String?)
}

private enum NavigationMode : Int {
    case wikitext
    case abuseFilterWarning
    case abuseFilterDisallow
    case preview
    case captcha
}

class EditSaveViewController: WMFScrollViewController, Themeable, UITextFieldDelegate, UIScrollViewDelegate, WMFCaptchaViewControllerDelegate, EditSummaryViewDelegate {

    struct SaveData {
        let summmaryText: String
        let isMinorEdit: Bool
        let shouldAddToWatchList: Bool
    }

    var savedData: SaveData?

    var sectionID: Int?
    var pageURL: URL?
    var languageCode: String?
    var dataStore: MWKDataStore?
    var source: EditorViewController.Source?
    
    var wikitext = ""
    var theme: Theme = .standard
    var needsWebPreviewButton: Bool = false
    var needsSuppressPosting: Bool = false
    var editTags: [WMFEditTag]?
    var cannedSummaryTypes: [EditSummaryViewCannedButtonType] = [.typo, .grammar, .link]
    weak var delegate: EditSaveViewControllerDelegate?
    weak var editorLoggingDelegate: EditSaveViewControllerEditorLoggingDelegate?
    weak var imageRecLoggingDelegate: EditSaveViewControllerImageRecLoggingDelegate?

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
    
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet private var scrollContainer: UIView!
    private var buttonSave: UIBarButtonItem?
    private var buttonNext: UIBarButtonItem?
    private var buttonX: UIBarButtonItem?
    private var buttonLeftCaret: UIBarButtonItem?
    private var abuseFilterCode = ""
    private var summaryText = ""
    
    @IBOutlet weak var showWebPreviewContainerView: UIView!
    private var showWebPreviewButtonHostingController: UIHostingController<WMFSmallButton>?

    private var mode: NavigationMode = .preview {
        didSet {
            updateNavigation(for: mode)
        }
    }
    private let wikiTextSectionUploader = WikiTextSectionUploader()
    private let wikitextFetcher = WikitextFetcher()

    private var styles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.caption1, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCaption1, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCaption1, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.caption1, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 3)
    }

    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("wikitext-upload-save-terms-and-licenses-ccsa4", languageCode: languageCode, value: "By publishing changes, you agree to the %1$@Terms of Use%2$@, and you irrevocably agree to release your contribution under the %3$@CC BY-SA 4.0%4$@ License and the %5$@GFDL%6$@. You agree that a hyperlink or URL is sufficient attribution under the Creative Commons license.", comment: "Text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.")

        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA4URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )

        let attributedString = NSAttributedString.attributedStringFromHtml(substitutedString, styles: styles)
        return attributedString
    }

    private var licenseLoginTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("wikitext-upload-save-anonymously-or-login", languageCode: languageCode, value: "Edits will be attributed to the IP address of your device. If you %1$@Log in%2$@ you will have more privacy.", comment: "Text informing user of draw-backs of not signing in before saving wikitext. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting.")

        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"#LOGIN_HREF\">", // "#LOGIN_HREF" ensures 'nsAttributedStringFromHtml' doesn't strip the anchor. The entire text view uses a tap recognizer so the string itself is unimportant.
            "</a>"
        )

        let attributedString = NSAttributedString.attributedStringFromHtml(substitutedString, styles: styles)
        return attributedString
    }


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
        
        imageRecLoggingDelegate?.logEditSaveViewControllerDidTapBack()
        
        delegate?.editSaveViewControllerWillCancel(SaveData(summmaryText: summaryText, isMinorEdit: minorEditToggle.isOn, shouldAddToWatchList: addToWatchlistToggle.isOn))
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func goForward() {
        switch mode {
        case .abuseFilterWarning:
            save()
        case .captcha:
            save()
        default:
            save()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupButtonsAndTitle()
        mode = .preview

        for dividerHeightContraint in dividerHeightConstraits {
            dividerHeightContraint.constant = 1.0 / UIScreen.main.scale
        }
        
        let isPermanent = dataStore?.authenticationManager.authStateIsPermanent ?? false
        
        if !isPermanent {
            addToWatchlistStackView.isHidden = true
        }

        updateTextViews()
        apply(theme: theme)

        captchaViewController?.captchaDelegate = self
        captchaViewController?.apply(theme: theme)
        wmf_add(childController: captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)

        let vc = EditSummaryViewController(nibName: EditSummaryViewController.wmf_classStoryboardName(), bundle: nil)
        vc.delegate = self
        vc.apply(theme: theme)
        vc.setLanguage(for: pageURL)
        vc.cannedSummaryTypes = cannedSummaryTypes
        wmf_add(childController: vc, andConstrainToEdgesOfContainerView: editSummaryVCContainer)

        if isPermanent {
            licenseLoginTextView.isHidden = true
        }

        if let savedData = savedData {
            vc.updateInputText(to: savedData.summmaryText)
            minorEditToggle.isOn = savedData.isMinorEdit
            addToWatchlistToggle.isOn = savedData.shouldAddToWatchList
        }
        
        addToWatchlistToggle.addTarget(self, action: #selector(toggledWatchlist), for: .valueChanged)
        fetchWatchlistStatusAndUpdateToggle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageRecLoggingDelegate?.logEditSaveViewControllerDidAppear()
    }

    func setupSemanticContentAttibute() {
        let semanticContentAttibute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: languageCode)
        for subview in stackView.subviews {
            subview.semanticContentAttribute = semanticContentAttibute
        }
        licenseLoginTextView.semanticContentAttribute = semanticContentAttibute
        licenseLoginTextView.textAlignment = semanticContentAttibute == .forceRightToLeft ? .right : .left
        licenseTitleTextView.semanticContentAttribute = semanticContentAttibute
        licenseTitleTextView.textAlignment = semanticContentAttibute == .forceRightToLeft ? .right : .left
    }
    
    @objc private func toggledWatchlist() {
        imageRecLoggingDelegate?.logEditSaveViewControllerDidToggleWatchlist(isOn: addToWatchlistToggle.isOn)
    }

    private func setupButtonsAndTitle() {
        navigationItem.title = WMFLocalizedString("wikitext-preview-save-changes-title", value: "Save changes", comment: "Title for edit preview screens")
        buttonX = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(self.goBack))
        buttonLeftCaret = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(self.goBack))

        buttonSave = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(self.goForward))
        buttonSave?.tintColor = theme.colors.secondaryText

        minorEditLabel.text = WMFLocalizedString("edit-minor-text", languageCode: languageCode, value: "This is a minor edit", comment: "Text for minor edit label")
        minorEditButton.setTitle(WMFLocalizedString("edit-minor-learn-more-text", languageCode: languageCode, value: "Learn more about minor edits", comment: "Text for minor edits learn more button"), for: .normal)

        addToWatchlistLabel.text = WMFLocalizedString("edit-watch-this-page-text", languageCode: languageCode, value: "Watch this page", comment: "Text for watch this page label")
        addToWatchlistButton.setTitle(WMFLocalizedString("edit-watch-list-learn-more-text", languageCode: languageCode, value: "Learn more about your Watchlist", comment: "Text for watch lists learn more button"), for: .normal)

        setupWebPreviewButton()
    }
    
    private func setupWebPreviewButton() {
        
        guard needsWebPreviewButton else {
            showWebPreviewContainerView.isHidden = true
            return
        }
        
        let configuration = WMFSmallButton.Configuration(style: .quiet)
        let rootView = WMFSmallButton(configuration: configuration, title: WMFLocalizedString("edit-show-web-preview", languageCode: languageCode, value: "Show web preview", comment: "Title of button that will show a web preview of the edit.")) { [weak self] in
            self?.delegate?.editSaveViewControllerDidTapShowWebPreview()
            self?.editorLoggingDelegate?.logEditSaveViewControllerDidTapShowWebPreview()
        }
         let showWebPreviewButtonHostingController = UIHostingController(rootView: rootView)
         showWebPreviewButtonHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        showWebPreviewButtonHostingController.view.backgroundColor = .clear
         self.showWebPreviewButtonHostingController = showWebPreviewButtonHostingController
         
         addChild(showWebPreviewButtonHostingController)
         showWebPreviewContainerView.addSubview(showWebPreviewButtonHostingController.view)
         
        showWebPreviewContainerView.addConstraints([
            showWebPreviewContainerView.topAnchor.constraint(equalTo: showWebPreviewButtonHostingController.view.topAnchor),
            showWebPreviewContainerView.bottomAnchor.constraint(equalTo: showWebPreviewButtonHostingController.view.topAnchor),
            showWebPreviewContainerView.trailingAnchor.constraint(equalTo: showWebPreviewButtonHostingController.view.trailingAnchor)
        ])
    }
    
    private func fetchWatchlistStatusAndUpdateToggle() {
        guard let siteURL = pageURL?.wmf_site,
           let project = WikimediaProject(siteURL: siteURL)?.wmfProject,
            let title = pageURL?.wmf_title else {
            return
        }
        
        let dataController = WMFWatchlistDataController()
        dataController.fetchWatchStatus(title: title, project: project) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    self?.addToWatchlistToggle.isOn = status.watched
                case .failure:
                    break
                }
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTextViews()
    }
    
    private func updateTextViews() {
        licenseTitleTextView.textContainerInset = .zero
        licenseLoginTextView.textContainerInset = .zero
        licenseTitleTextView.textContainer.lineFragmentPadding = 0
        licenseLoginTextView.textContainer.lineFragmentPadding = 0
        
        licenseTitleTextView.attributedText = licenseTitleTextViewAttributedString
        licenseLoginTextView.attributedText = licenseLoginTextViewAttributedString
        applyThemeToTextViews()
        setupSemanticContentAttibute()
    }
    
    @IBAction public func licenseLoginLabelTapped(_ recognizer: UIGestureRecognizer?) {
        if recognizer?.state == .ended {
            guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
                assertionFailure("Expected view controller")
                return
            }

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
        
        guard let editURL = pageURL else {
            assertionFailure("Could not get url of section to be edited")
            return
        }
        
        let isMinor = minorEditToggle.isOn
        let isWatched = addToWatchlistToggle.isOn
        
        if let source,
           let pageURL,
        let project = WikimediaProject(siteURL: pageURL) {
            let summaryAdded = !summaryText.isEmpty
            
            editorLoggingDelegate?.logEditSaveViewControllerDidTapPublish(source: source, summaryAdded: summaryAdded, isMinor: isMinor, isWatched: isWatched, project: project)
            
        }
        
        imageRecLoggingDelegate?.logEditSaveViewControllerDidTapPublish(minorEditEnabled: isMinor, watchlistEnabled: isWatched)
        
        EditAttemptFunnel.shared.logSaveAttempt(pageURL: editURL)
        
        let section: String?
        if let sectionID {
            section = "\(sectionID)"
        } else {
            section = nil
        }
        
        guard !needsSuppressPosting else {
            let result = ["newrevid": UInt64(0)]
            self.handleEditSuccess(with: result)
            return
        }
        
        let editTagStrings = editTags?.map { $0.rawValue }
        
        wikiTextSectionUploader.uploadWikiText(wikitext, forArticleURL: editURL, section: section, summary: summaryText, isMinorEdit: minorEditToggle.isOn, addToWatchlist: addToWatchlistToggle.isOn, baseRevID: nil, captchaId: captchaViewController?.captcha?.captchaID, captchaWord: captchaViewController?.solution, editTags: editTagStrings, completion: { (result, error) in
            
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
        let notifyDelegate: (Result<EditorChanges, Error>) -> Void = { result in
            self.delegate?.editSaveViewControllerDidSave(self, result: result)
        }
        guard let fetchedData = result as? [String: Any],
              let newRevID = fetchedData["newrevid"] as? UInt64 else {
            assertionFailure("Could not extract rev id as Int")
            DispatchQueue.main.async {
                notifyDelegate(.failure(RequestError.unexpectedResponse))
            }
            return
        }
        
        let completion: (UInt64, String?) -> Void = { [weak self] newRevID, fullArticleWikitextForAltTextExperiment in
            
            guard let self else {
                return
            }
            
            DispatchQueue.main.async {
                
                if let pageURL = self.pageURL,
                   let project = WikimediaProject(siteURL: pageURL) {
                    
                    if let source = self.source {
                        self.editorLoggingDelegate?.logEditSaveViewControllerPublishSuccess(source: source, revisionID: newRevID, project: project)
                    }
                    
                    EditAttemptFunnel.shared.logSaveSuccess(pageURL: pageURL, revisionId: Int(newRevID))
                    
                }
                
                self.imageRecLoggingDelegate?.logEditSaveViewControllerPublishSuccess(revisionID: Int(newRevID), summaryAdded: !self.summaryText.isEmpty)
                
                notifyDelegate(.success(EditorChanges(newRevisionID: newRevID, fullArticleWikitextForAltTextExperiment: fullArticleWikitextForAltTextExperiment)))
            }
        }
        
        // If needed, load full article wikitext for alt text experiment.
        // We are doing lots of checks here so the fewest number of people take the additional load.
        let isPermanent = dataStore?.authenticationManager.authStateIsPermanent ?? false
        if sectionID != nil, // if sectionID is nil, then wikitext property already represents the latest full article posted wikitext. If sectionID is populated, then we need to fetch the full article wikitext
           let altTextDataController = WMFAltTextDataController(),
           let pageURL,
           let project = WikimediaProject(siteURL: pageURL)?.wmfProject,
           altTextDataController.shouldFetchFullArticleWikitextFromArticleEditor(isPermanent: isPermanent, project: project) {
            wikitextFetcher.fetchSection(with: nil, articleURL: pageURL, revisionID: newRevID) { result in
                switch result {
                case .success(let response):
                    let fullArticleWikitext = response.wikitext
                    completion(newRevID, fullArticleWikitext)
                default:
                    completion(newRevID, nil)
                }
            }
        } else if sectionID == nil {
            // self.wikitext property already represents the full article wikitext
            completion(newRevID, wikitext)
        } else {
            completion(newRevID, nil)
        }
    }
    
    private func handleEditFailure(with error: Error) {
        let nsError = error as NSError
        let errorType = WikiTextSectionUploaderErrorType.init(rawValue: nsError.code) ?? .unknown

        var problemSource: EditInteractionFunnel.ProblemSource?
        
        switch errorType {
        case .needsCaptcha:
            let captchaUrl = URL(string: nsError.userInfo["captchaUrl"] as? String ?? "")
            let captchaId = nsError.userInfo["captchaId"] as? String ?? ""
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            captchaViewController?.captcha = WMFCaptcha(captchaID: captchaId, captchaURL: captchaUrl!)
            mode = .captcha
            highlightCaptchaSubmitButton(false)
            dispatchOnMainQueueAfterDelayInSeconds(0.1) { // Prevents weird animation.
                self.captchaViewController?.captchaTextFieldBecomeFirstResponder()
            }
            problemSource = .needsCaptcha
        case .abuseFilterDisallowed, .abuseFilterWarning, .abuseFilterOther:
            wmf_hideKeyboard()
            WMFAlertManager.sharedInstance.dismissAlert() // Hide "Publishing..."
            
            guard let displayError = nsError.userInfo[NSErrorUserInfoDisplayError] as? MediaWikiAPIDisplayError,
                  let currentTitle = pageURL?.wmf_title else {
                return
            }
            
            if errorType == .abuseFilterDisallowed {
                mode = .abuseFilterDisallow
                abuseFilterCode = displayError.code

                wmf_showAbuseFilterDisallowPanel(messageHtml: displayError.messageHtml, linkBaseURL: displayError.linkBaseURL, currentTitle: currentTitle, theme: theme, goBackIsOnlyDismiss: false)
                
                problemSource = .abuseFilterBlocked
            } else {
                mode = .abuseFilterWarning
                abuseFilterCode = displayError.code
                
                wmf_showAbuseFilterWarningPanel(messageHtml: displayError.messageHtml, linkBaseURL: displayError.linkBaseURL, currentTitle: currentTitle, theme: theme, goBackIsOnlyDismiss: false, publishAnywayTapHandler: { [weak self] _, _ in
                    
                    self?.dismiss(animated: true) {
                        self?.save()
                    }
                    
                })
                
                problemSource = .abuseFilterWarned
            }
            
        case .server:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            problemSource = .serverError
        case .blocked:
            
            WMFAlertManager.sharedInstance.dismissAlert() // Hide "Publishing..."
            
            guard let displayError = nsError.userInfo[NSErrorUserInfoDisplayError] as? MediaWikiAPIDisplayError,
                  let currentTitle = pageURL?.wmf_title else {
                return
            }
            
            wmf_showBlockedPanel(messageHtml: displayError.messageHtml, linkBaseURL: displayError.linkBaseURL, currentTitle: currentTitle, theme: theme, linkLoggingAction: { [weak self] in
                
                guard let self else {
                    return
                }
                
                if let source,
                   let pageURL,
                let project = WikimediaProject(siteURL: pageURL) {
                    
                    editorLoggingDelegate?.logEditSaveViewControllerDidTapBlockedMessageLink(source: source, project: project)
                    
                    EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
                }
            })
            
            problemSource = .blockedMessage
            
        case .protectedPage:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            problemSource = .protectedPage
        case .unknown:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            // leaving problemSource blank
        default:
            WMFAlertManager.sharedInstance.showErrorAlert(nsError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            if nsError.wmf_isNetworkConnectionError() {
                problemSource = .connectionError
            }
        }
        
        if let pageURL,
        let project = WikimediaProject(siteURL: pageURL) {
            
            if let source {
                editorLoggingDelegate?.logEditSaveViewControllerPublishFailed(source: source, problemSource: problemSource, project: project)
            }
            
            
            EditAttemptFunnel.shared.logSaveFailure(pageURL: pageURL)
        }
        
        imageRecLoggingDelegate?.logEditSaveViewControllerLogPublishFailed(abortSource: problemSource?.rawValue)
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
        return pageURL?.wmf_site ?? Configuration.current.defaultSiteURL
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
        navigate(to: URL(string: "https://meta.wikimedia.org/wiki/Help:Edit_summary"))
    }

    @IBAction public func minorEditButtonTapped(sender: UIButton) {
        imageRecLoggingDelegate?.logEditSaveViewControllerDidTapMinorEditsLearnMore()
        navigate(to: URL(string: "https://www.mediawiki.org/wiki/Special:MyLanguage/Help:Minor_edit"))
    }

    @IBAction public func watchlistButtonTapped(sender: UIButton) {
        imageRecLoggingDelegate?.logEditSaveViewControllerDidTapWatchlistLearnMore()
        navigate(to: URL(string: "https://www.mediawiki.org/wiki/Help:Watching_pages"))
    }

    func summaryChanged(newSummary: String) {
        summaryText = newSummary
        buttonSave?.tintColor = newSummary.isEmpty ? theme.colors.secondaryText : theme.colors.link
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

extension EditSaveViewController: EditingFlowViewController {
    
}
