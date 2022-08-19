import Foundation
import WMF
import CocoaLumberjackSwift

protocol TalkPageViewModelDelegate: AnyObject {
    func talkPageDataDidUpdate()
}

final class TalkPageViewModel {

    // MARK: - Properties

    let pageType: TalkPageType
    private let pageTitle: String
    private let siteURL: URL
    private let dataController: TalkPageDataController
    weak var delegate: TalkPageViewModelDelegate?

    // TODO: - Populate from data controller
    private(set) var headerTitle: String
    private(set) var headerDescription: String?
    private(set) var leadImageURL: URL?
    private(set) var coffeeRollText: String?
    var projectSourceImage: UIImage? = UIImage(named: "notifications-project-mediawiki")
    var projectLanguage: String? = "EN"
    
    static let leadImageSideLength = 98
    
    var theme: Theme = .light

    // MARK: - Lifecycle

    /// Main required init
    /// - Parameters:
    ///   - pageType: TalkPageType - e.g. .article or .user
    ///   - pageTitle: Wiki page title, e.g. "Talk:Cat" or "User_talk:Jimbo"
    ///   - siteURL: Site URL without article path, e.g. "https://en.wikipedia.org"
    ///   - articleSummaryController: article summary controller from the MWKDataStore singleton
    init(pageType: TalkPageType, pageTitle: String, siteURL: URL, articleSummaryController: ArticleSummaryController) {
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.dataController = TalkPageDataController(pageType: pageType, pageTitle: pageTitle, siteURL: siteURL, articleSummaryController: articleSummaryController)
        
        // Setting headerTitle as pageTitle (which contains the namespace prefix) for now, we attempt to strip the namespace later in populateHeaderData
        self.headerTitle = pageTitle
    }
    
    /// Convenience init for paths that do not already have pageTitle and siteURL separated
    /// - Parameters:
    ///   - pageType: TalkPageType - e.g. .article or .user
    ///   - pageURL: Full wiki page URL, e.g. https://en.wikipedia.org/wiki/Cat
    ///   - articleSummaryController: article summary controller from the MWKDataStore singleton
    convenience init?(pageType: TalkPageType, pageURL: URL, articleSummaryController: ArticleSummaryController) {
        guard let pageTitle = pageURL.wmf_title, let siteURL = pageURL.wmf_site else {
            return nil
        }

        self.init(pageType: pageType, pageTitle: pageTitle, siteURL: siteURL, articleSummaryController: articleSummaryController)
    }

    // MARK: - Public

    func fetchTalkPage() {
        dataController.fetchTalkPage { [weak self] result in
            switch result {
            case .success(let result):
                self?.populateHeaderData(articleSummary: result.articleSummary, items: result.items)
                self?.delegate?.talkPageDataDidUpdate()
            case .failure(let error):
                DDLogError("Failure fetching talk page: \(error)")
                // TODO: Error handling
            }
        }
    }
    
    // MARK: - Private
    
    private func populateHeaderData(articleSummary: WMFArticle?, items: [TalkPageItem]) {
        
        if let languageCode = siteURL.wmf_languageCode {
            headerTitle = pageTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode).title
        }
        
        headerDescription = articleSummary?.wikidataDescription
        leadImageURL = articleSummary?.imageURL(forWidth: Self.leadImageSideLength)
        
        if let otherContent = items.first?.otherContent,
           !otherContent.isEmpty {
               coffeeRollText = items.first?.otherContent
        }
    }
}
