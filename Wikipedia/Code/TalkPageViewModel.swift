import Foundation
import WMF
import CocoaLumberjackSwift

final class TalkPageViewModel {
    
    struct DeepLinkData {
        let topicTitle: String
        let replyText: String?
    }

    // MARK: - Properties

    let pageType: TalkPageType

    private(set) var pageTitle: String
    private(set) var siteURL: URL
    private(set) var project: WikimediaProject
    let source: RoutingUserInfoSourceValue

    let authenticationManager: WMFAuthenticationManager
    let languageLinkController: MWKLanguageLinkController
    var deepLinkData: DeepLinkData?
    let dataController: TalkPageDataController
    
    private var dateFormatter: DateFormatter?
    private(set) var semanticContentAttribute: UISemanticContentAttribute

    private(set) var headerTitle: String
    private(set) var headerDescription: String?
    private(set) var leadImageURL: URL?
    private(set) var coffeeRollText: String?
    private(set) var projectSourceImage: UIImage?
    private(set) var projectLanguage: String?
    private(set) var latestRevisionID: Int?
    
    static let leadImageSideLength = 80
    
    var theme: Theme = .light
    private(set) var topics: [TalkPageCellViewModel] = []
    private(set) var shouldShowErrorState: Bool = false

    // MARK: - Lifecycle

    /// Main required init
    /// - Parameters:
    ///   - pageType: TalkPageType - e.g. .article or .user
    ///   - pageTitle: Wiki page title, e.g. "Talk:Cat" or "User_talk:Jimbo"
    ///   - siteURL: Site URL without article path, e.g. "https://en.wikipedia.org"
    ///   - articleSummaryController: article summary controller from the MWKDataStore singleton
    ///   - authenticationManager: authentication manager from the MWKDataStore singleton
    init?(pageType: TalkPageType, pageTitle: String, siteURL: URL, source: RoutingUserInfoSourceValue, articleSummaryController: ArticleSummaryController, authenticationManager: WMFAuthenticationManager, languageLinkController: MWKLanguageLinkController) {
        
        guard let project = WikimediaProject(siteURL: siteURL, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.project = project
        self.source = source
        self.dataController = TalkPageDataController(pageType: pageType, pageTitle: pageTitle, siteURL: siteURL, articleSummaryController: articleSummaryController)
        self.authenticationManager = authenticationManager
        self.languageLinkController = languageLinkController
        
        // Setting headerTitle as pageTitle (which contains the namespace prefix) for now, we attempt to strip the namespace later in populateHeaderData
        self.headerTitle = pageTitle
        
        self.dateFormatter = Self.dateFormatterForSiteURL(siteURL)
        self.semanticContentAttribute = Self.semanticContentAttributeForSiteURL(siteURL)
    }
    
    /// Convenience init for paths that do not already have pageTitle and siteURL separated
    /// - Parameters:
    ///   - pageType: TalkPageType - e.g. .article or .user
    ///   - pageURL: Full wiki page URL, e.g. https://en.wikipedia.org/wiki/Cat
    ///   - articleSummaryController: article summary controller from the MWKDataStore singleton
    ///   - authenticationManager: authentication manager from the MWKDataStore singleton
    convenience init?(pageType: TalkPageType, pageURL: URL, source: RoutingUserInfoSourceValue, articleSummaryController: ArticleSummaryController, authenticationManager: WMFAuthenticationManager, languageLinkController: MWKLanguageLinkController) {
        guard let pageTitle = pageURL.wmf_title, let siteURL = pageURL.wmf_site else {
            return nil
        }

        self.init(pageType: pageType, pageTitle: pageTitle, siteURL: siteURL, source: source, articleSummaryController: articleSummaryController, authenticationManager: authenticationManager, languageLinkController: languageLinkController)
    }

    // MARK: - Public
    
    func resetToNewSiteURL(_ siteURL: URL, pageTitle: String, project: WikimediaProject) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.project = project
        self.dateFormatter = Self.dateFormatterForSiteURL(siteURL)
        self.semanticContentAttribute = Self.semanticContentAttributeForSiteURL(siteURL)
        dataController.resetToNewSiteURL(siteURL, pageTitle: pageTitle)
    }

    var isUserPermanent: Bool {
        return authenticationManager.authStateIsPermanent
    }

    func fetchTalkPage(completion: @escaping (Result<Int?, Error>) -> Void) {
        dataController.fetchTalkPage { [weak self] result in
            
            guard let self = self else {
                return
            }

            switch result {
            case .success(let result):
                let oldViewModels: [TalkPageCellViewModel] = self.topics
                self.populateHeaderData(articleSummary: result.articleSummary, items: result.items)
                self.topics.removeAll()
                self.populateCellData(topics: result.items, oldViewModels: oldViewModels)
                self.updateSubscriptionForTopic(topicNames: result.subscribedTopicNames)
                self.shouldShowErrorState = false
                self.latestRevisionID = result.latestRevisionID
                completion(.success(result.latestRevisionID))
            case .failure(let error):
                DDLogError("Failure fetching talk page: \(error)")
                self.shouldShowErrorState = true
                completion(.failure(error))
            }
        }
    }

    func postTopic(topicTitle: String, topicBody: String, completion: @escaping (Result<Void, Error>) -> Void) {
        dataController.postTopic(topicTitle: topicTitle, topicBody: topicBody, completion: completion)
    }
    
    func postReply(commentId: String, comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        dataController.postReply(commentId: commentId, comment: comment, completion: completion)
    }
    

    func subscribe(to topic: String, shouldSubscribe: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        dataController.subscribeToTopic(topicName: topic, shouldSubscribe: shouldSubscribe) { result in
            switch result {
            case let .success(result) :
                completion(.success(result))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func updateSubscriptionForTopic(topicNames: [String]) {
        for topic in topics {
            for id in topicNames {
                if topic.topicName == id {
                    topic.isSubscribed = true
                }
            }
        }
    }


    func getTalkPageURL(encoded shouldPercentEncodeURL: Bool) -> URL? {
        var talkPageURLComponents = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        guard let encodedTitle = pageTitle.percentEncodedPageTitleForPathComponents else {
            return nil
        }

        let talkPageTitle = shouldPercentEncodeURL ? encodedTitle : pageTitle
        talkPageURLComponents?.path = "/wiki/\(talkPageTitle)"

        return talkPageURLComponents?.url
    }
    
    // MARK: - Private
    
    private static func dateFormatterForSiteURL(_ siteURL: URL) -> DateFormatter? {
        guard let languageCode = siteURL.wmf_languageCode else {
            return nil
        }
        
        return DateFormatter.wmf_localCustomShortDateFormatterWithTime(for: NSLocale.wmf_locale(for: languageCode))
    }
    
    private static func semanticContentAttributeForSiteURL(_ siteURL: URL) -> UISemanticContentAttribute {
        return MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: siteURL.wmf_contentLanguageCode)
    }
    
    private func populateHeaderData(articleSummary: WMFArticle?, items: [TalkPageItem]) {
        
        headerTitle = pageTitle.namespaceAndTitleOfWikiResourcePath(with: project.languageCode ?? "en").title
        headerDescription = articleSummary?.wikidataDescription

        leadImageURL = articleSummary?.imageURL(forWidth: Self.leadImageSideLength * Int(UIScreen.main.scale))
        
        if let coffeeRollResult = coffeeRollFromItems(items) {
            coffeeRollText = coffeeRollResult.0.otherContent
        } else {
            coffeeRollText = nil
        }
        
        if let projectIconName = project.projectIconName {
           projectSourceImage = UIImage(named: projectIconName)
        }
        
        if let projectLanguage = project.languageCode {
            self.projectLanguage = projectLanguage
        }
    }
    
    private func populateCellData(topics: [TalkPageItem], oldViewModels: [TalkPageCellViewModel]) {
        
        let cleanTopics = cleanTalkPageItems(items: topics)
        
        for topic in cleanTopics {
            
            guard let topicTitleHtml = topic.html else {
                DDLogDebug("Missing topic title. Skipping topic.")
                continue
            }
            
            guard let topicName = topic.name else {
                DDLogWarn("Unable to parse topic name")
                continue
            }
            
            // If we cannot detect any replies to traverse but there is other content to display,
            // set up cell view model with otherContent and continue to next topic
            if let otherContent = topic.otherContent,
               topic.replies.isEmpty {
                let topicViewModel = TalkPageCellViewModel(id: topic.id, topicTitleHtml: topicTitleHtml, timestamp: nil, topicName: topicName, leadComment: nil, otherContentHtml: otherContent, replies: [], activeUsersCount: nil, isUserPermanent: isUserPermanent, dateFormatter: dateFormatter)
                self.topics.append(topicViewModel)
                continue
            }
            
            // Parse through topic replies and set up comment view models
            guard let firstReply = topic.replies.first else {
                DDLogDebug("Unable to parse lead comment. Skipping topic.")
                continue
            }
            
            let firstReplyHtml = firstReply.html
            
            guard let leadCommentViewModel = TalkPageCellCommentViewModel(commentId: firstReply.id, html: firstReplyHtml, author: firstReply.author, authorTalkPageURL: "", timestamp: firstReply.timestamp, replyDepth: firstReply.level, talkPageURL: getTalkPageURL(encoded: false)) else {
                DDLogDebug("Unable to parse lead comment. Skipping topic.")
                continue
            }
            
            let remainingReplies = Array(topic.replies.suffix(from: 1))
            
            let remainingCommentViewModels: [TalkPageCellCommentViewModel] = remainingReplies.compactMap {
                
                // API considers headers as level 0, so comments comes back as level 1 = no indention, level 2 = 1 indention, etc.
                // Offsetting this by one for replyDepth so that 0 = no indention, 1 = 1 indention, etc.
                
                var replyDepth: Int?
                if let level = $0.level,
                level > 0 {
                    replyDepth = level - 1
                }
                
                let remainingReplyHtml = $0.html
                
                return TalkPageCellCommentViewModel(commentId: $0.id, html: remainingReplyHtml, author: $0.author, authorTalkPageURL: "", timestamp: $0.timestamp, replyDepth: replyDepth, talkPageURL: getTalkPageURL(encoded: false))
            }
            
            let activeUsersCount = activeUsersCount(topic: topic)

            let topicViewModel = TalkPageCellViewModel(id: topic.id, topicTitleHtml: topicTitleHtml, timestamp: firstReply.timestamp, topicName: topicName, leadComment: leadCommentViewModel, otherContentHtml: nil, replies: remainingCommentViewModels, activeUsersCount: activeUsersCount, isUserPermanent: isUserPermanent, dateFormatter: dateFormatter)
            topicViewModel.viewModel = self

            // Note this is a nested loop, so it will not perform well with many topics.
            // Talk pages generally have a limited number of topics, so optimize later if we determine it's needed
            assignExpandedFlag(to: topicViewModel, from: oldViewModels)
            
            // It is beneficial for comment view models to have a weak reference to their parent cell view model - it is used for scrolling enhancements after replying
            let commentViewModels = (remainingCommentViewModels + [leadCommentViewModel])
            assignCellViewModel(topicViewModel, to: commentViewModels)
            
            self.topics.append(topicViewModel)
        }
    }
    
    private func assignExpandedFlag(to newViewModel: TalkPageCellViewModel, from oldViewModels: [TalkPageCellViewModel]) {
        if let oldTopicViewModel = oldViewModels.first(where: { $0.id == newViewModel.id }) {
            newViewModel.isThreadExpanded = oldTopicViewModel.isThreadExpanded
        }
    }
    
    private func assignCellViewModel(_ cellViewModel: TalkPageCellViewModel, to commentViewModels: [TalkPageCellCommentViewModel]) {
        for commentViewModel in commentViewModels {
            commentViewModel.cellViewModel = cellViewModel
        }
    }
    
    private func activeUsersCount(topic: TalkPageItem) -> Int {
        var distinctUsers: Set<String> = []
        
        for item in topic.replies {
            if let author = item.author {
                distinctUsers.insert(author)
            }
        }
        
        return distinctUsers.count
    }
}


// MARK: TalkPageItem Transform Methods

private extension TalkPageViewModel {

    /// Clean up talk page items so that we can more easily translate them into view models
    ///
    /// The talk page response returns items in a tree structure. To simplify the response to more closely match our design, we are flattening the items into one top-level list of topics, each with one level of replies. We also clear out the first coffee roll item.
    func cleanTalkPageItems(items: [TalkPageItem]) -> [TalkPageItem] {
        let topics = self.removingSubtopics(items: items)
        let validTopics = self.validTopLevelTopics(items: topics)
        let topicsWithFlattenedReplies = self.topicsWithFlattenedReplies(items: validTopics)
        
        return topicsWithFlattenedReplies
    }
    
    func removingSubtopics(items: [TalkPageItem]) -> [TalkPageItem] {
        
        // Subtopics are already returned at the top level from the API, so we're just removing duplicate nested subtopics here.
        var newItems: [TalkPageItem] = []
        for item in items {
            
            var newReplies: [TalkPageItem] = []
            for reply in item.replies {
                
                if reply.type == .heading {
                    continue
                }
                
                newReplies.append(reply)
            }
            
            let newItem = item.updatingReplies(replies: newReplies)
            newItems.append(newItem)
            
        }
        
        return newItems
    }
    
    func topicsWithFlattenedReplies(items: [TalkPageItem]) -> [TalkPageItem] {
        var topicsWithFlattenedReplies: [TalkPageItem] = []
        
        for item in items {
            guard item.type == .heading else {
                assertionFailure("Unexpected top-level topic type")
                continue
            }
            
            var flattenedReplies: [TalkPageItem] = []
            recursivelyFlattenReplies(items: item.replies, flattenedItems: &flattenedReplies)
            
            // At this point replies are already flattened, but we want to remove their inner replies just for cleanliness
            let nonNestedReplies = flattenedReplies.map { $0.updatingReplies(replies: []) }
            
            let newItem = item.updatingReplies(replies: nonNestedReplies)
            topicsWithFlattenedReplies.append(newItem)
        }
        return topicsWithFlattenedReplies
    }
    
    /// Method to seek out coffee roll item from an array of talk page items
    /// - Parameter items: Array of talk page items
    /// - Returns: Tuple containing the coffee roll talk page item and the index where it appears in the array
    func coffeeRollFromItems(_ items: [TalkPageItem]) -> (TalkPageItem, Int)? {
        if let firstItem = items.first {
            let otherContent = firstItem.otherContent ?? ""
            let title = firstItem.html ?? ""
            if firstItem.type == .heading && firstItem.replies.isEmpty && title.isEmpty && !otherContent.isEmpty {
                return (firstItem, 0)
            }
        }
            
        return nil
    }
    
    func validTopLevelTopics(items: [TalkPageItem]) -> [TalkPageItem] {
        
        var finalItems: [TalkPageItem] = items
        
        // Trim first item if it indicates it's a coffee roll:
        
        if let coffeeRollResult = coffeeRollFromItems(items) {
            finalItems.remove(at: coffeeRollResult.1)
        }
        
        // Filter out items with no content to show
        finalItems = finalItems.filter { item in
            if item.replies.isEmpty && (item.html ?? "").isEmpty && (item.otherContent ?? "").isEmpty {
                return false
            }
            
            return true
        }
        
        return finalItems
    }
    
    func recursivelyFlattenReplies(items: [TalkPageItem], flattenedItems: inout [TalkPageItem]) {
        
        for item in items {
            if item.type == .comment {
                flattenedItems.append(item)
            }
            
            recursivelyFlattenReplies(items: item.replies, flattenedItems: &flattenedItems)
        }
    }
}
