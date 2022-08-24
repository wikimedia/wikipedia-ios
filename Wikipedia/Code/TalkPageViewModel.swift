import Foundation

final class TalkPageViewModel {

    // MARK: - Nested Types

    enum PageType {
        case article
        case user
    }

    // MARK: - Properties

    private let pageTitle: String
    private let siteURL: URL

    // TODO: - Populate from data controller
    var pageType = PageType.user
    let talkPageTitle: String = "Page title"
    var description: String? = "This is the page description"
    var leadImage: UIImage? = UIImage(systemName: "text.bubble.fill")
    var coffeeRollText: NSAttributedString? = NSAttributedString(string: "This is the coffee roll")
    var projectSourceImage: UIImage? = UIImage(named: "notifications-project-mediawiki")
    var projectLanguage: String? = "EN"

    // MARK: - Lifecycle

    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    convenience init?(siteURL: URL) {
        guard let pageTitle = siteURL.wmf_title, let siteURL = siteURL.wmf_site else {
            return nil
        }

        self.init(pageTitle: pageTitle, siteURL: siteURL)
    }

    // MARK: - Public

}
