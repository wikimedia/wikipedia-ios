@preconcurrency import WebKit
import CocoaLumberjackSwift
import WMF
import WMFComponents
import WMFData

@objc class TempAccountExpiryViewController: ThemeableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: CommonStrings.accessibilityBackTitle,
            style: .plain,
            target: self,
            action: #selector(dismissView)
        )
    }
    
    private var styles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.boldHeadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }

    var informationLabelText: NSAttributedString {
        let openingLinkLogIn = "<a href=\"\">"
        let openingLinkCreateAccount = "<a href=\"\">"
        let openingLinkOtherFeatures = "<a href=\"\">"
        let closingLink = "</a>"
        let openingBold = "<strong>"
        let closingBold = "</strong>"
        let lineBreaks = "<br/><br/>"

        let format = WMFLocalizedString("temp-account-alert-read-more-information", value: "%1$@You are using a temporary account.%2$@ Account will expire in 90 days. After it expires, a new one will be created the next time you make an edit without logging in. %3$@ %4$@Log in%5$@ or %6$@create an account%5$@ to get credit for future edits, and access %7$@other features%5$@.",
          comment: "Information on temporary accounts, $1 is the opening bold, $2 is the closing bold, $3 is the line breaks, $4 is the opening log in link, $5 is the closing. $6 is the opening create an account link, $7 is the opening link for other features.")

        let htmlString = String.localizedStringWithFormat(format, openingBold, closingBold, lineBreaks, openingLinkLogIn, closingLink, openingLinkCreateAccount, openingLinkOtherFeatures)

        guard let data = htmlString.data(using: .utf8) else { return NSAttributedString(string: htmlString) }
        
        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
        } catch {
            return NSAttributedString(string: htmlString)
        }
    }

    
    private func setUpView() {
        view.backgroundColor = .white

        self.title = CommonStrings.tempAccount

        let informationLabel = UILabel()
        informationLabel.attributedText = informationLabelText
        informationLabel.font = nil
        informationLabel.textAlignment = .left
        informationLabel.numberOfLines = 0
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationLabel)

        NSLayoutConstraint.activate([
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            informationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
