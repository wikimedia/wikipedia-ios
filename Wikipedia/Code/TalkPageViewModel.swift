import Foundation
import WMF

final class TalkPageViewModel {

    // MARK: - Nested Types

    enum PageType {
        case article
        case user
    }

    // MARK: - Properties

    private let pageTitle: String
    private let siteURL: URL
    private let dataController: TalkPageDataController

    // TODO: - Populate from data controller
    var pageType = PageType.user
    let talkPageTitle: String = "Page title"
    var description: String? = "This is the page description"
    var leadImage: UIImage? = UIImage(systemName: "text.bubble.fill")
    var coffeeRollText: NSAttributedString? = NSAttributedString(string: "This is the coffee roll")
    var projectSourceImage: UIImage? = UIImage(named: "notifications-project-mediawiki")
    var projectLanguage: String? = "EN"

    // MARK: - Lifecycle

    init(pageTitle: String, siteURL: URL, articleSummaryController: ArticleSummaryController) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.dataController = TalkPageDataController(pageTitle: pageTitle, siteURL: siteURL, articleSummaryController: articleSummaryController)
    }
    
    convenience init?(siteURL: URL, articleSummaryController: ArticleSummaryController) {
        guard let pageTitle = siteURL.wmf_title, let siteURL = siteURL.wmf_site else {
            return nil
        }

        self.init(pageTitle: pageTitle, siteURL: siteURL, articleSummaryController: articleSummaryController)
    }

    // MARK: - Public

}
