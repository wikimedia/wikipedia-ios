import MessageUI

@objc(WMFHelpViewController)
class HelpViewController: SinglePageWebViewController {
    static let faqURLString = "https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"
    static let emailAddress = "mobile-ios-wikipedia@wikimedia.org"
    static let emailSubject = "Bug:"
    
    @objc init?(dataStore: MWKDataStore, theme: Theme) {
        guard let faqURL = URL(string: HelpViewController.faqURLString) else {
            return nil
        }
        super.init(url: faqURL, theme: theme)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(url: URL, theme: Theme) {
        fatalError("init(url:theme:) has not been implemented")
    }

    required init(url: URL, theme: Theme, doesUseSimpleNavigationBar: Bool = false) {
        fatalError("init(url:theme:doesUseSimpleNavigationBar:) has not been implemented")
    }

    lazy var sendEmailToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(title: WMFLocalizedString("button-report-a-bug", value: "Report a bug", comment: "Button text for reporting a bug"), style: .plain, target: self, action: #selector(sendEmail))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = nil
        setupToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func sendEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(WMFLocalizedString("no-email-account-alert", value: "Please setup an email account on your device and try again.", comment: "Displayed to the user when they try to send a feedback email, but they have never set up an account on their device"), sticky: false, dismissPreviousAlerts: false)
            return
        }
        let vc = MFMailComposeViewController()
        vc.setSubject(HelpViewController.emailSubject)
        vc.setToRecipients([HelpViewController.emailAddress])
        vc.setMessageBody("\n\n\n\nVersion: \(WikipediaAppUtils.versionedUserAgent())", isHTML: false)
        if let data = DDLog.wmf_currentLogFile()?.data(using: .utf8) {
            vc.addAttachmentData(data, mimeType: "text/plain", fileName: "Log.txt")
        }
        vc.mailComposeDelegate = self
        present(vc, animated: true)
    }
    
    private func setupToolbar() {
        enableToolbar()
        toolbar.items = [UIBarButtonItem.flexibleSpaceToolbar(), sendEmailToolbarItem, UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 8)]
        setToolbarHidden(false, animated: false)
    }
}

extension HelpViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }
}
