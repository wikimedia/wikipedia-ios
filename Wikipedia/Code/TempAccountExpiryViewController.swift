@preconcurrency import WebKit
import CocoaLumberjackSwift
import WMF
import WMFComponents
import WMFData

@objc class TempAccountExpiryViewController: ThemeableViewController {
    var category: EventCategoryMEP?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: CommonStrings.accessibilityBackTitle,
            style: .plain,
            target: self,
            action: #selector(dismissView)
        )
    }
    
    @objc
    public func start() {
        setUpView()
    }
    
    private var styles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.boldHeadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }

    var informationLabelText: NSAttributedString {
        let openingBold = "<b>"
        let closingBold = "</b>"
        let lineBreaks = "<br/><br/>"

        let format = WMFLocalizedString(
            "temp-account-alert-read-more-information",
            value: "%1$@You are using a temporary account.%2$@ Account will expire in 90 days. After it expires, a new one will be created the next time you make an edit without logging in. %3$@Log in or create an account to get credit for future edits, and access other features.",
            comment: "Information on temporary accounts, $1 is the opening bold, $2 is the closing bold, $3 is the line breaks."
        )

        let htmlString = String.localizedStringWithFormat(format, openingBold, closingBold, lineBreaks)

        let attributedText = NSMutableAttributedString.mutableAttributedStringFromHtml(htmlString, styles: styles)
        
        return attributedText
    }
    
    private func setUpView() {
        view.backgroundColor = .white

        self.title = CommonStrings.tempAccount

        let informationLabel = UILabel()
        informationLabel.attributedText = informationLabelText
        informationLabel.textAlignment = .left
        informationLabel.numberOfLines = 0
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationLabel)
        
        let logInButton = UIButton(type: .system)
        logInButton.setTitle(CommonStrings.loginOrCreateAccountTitle, for: .normal)
        logInButton.setTitleColor(theme.colors.paperBackground, for: .normal)
        logInButton.titleLabel?.font = WMFFont.for(.semiboldHeadline)
        logInButton.backgroundColor = theme.colors.link
        logInButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        logInButton.translatesAutoresizingMaskIntoConstraints = false
        logInButton.layer.cornerRadius = 8
        logInButton.clipsToBounds = true
        view.addSubview(logInButton)
        
        NSLayoutConstraint.activate([
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            informationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            logInButton.topAnchor.constraint(equalTo: informationLabel.bottomAnchor, constant: 20),
            logInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 13),
            logInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -13),
            logInButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc
    private func login() {
        guard let navigationController else { return }
        let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme)
        loginCoordinator.start()
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
