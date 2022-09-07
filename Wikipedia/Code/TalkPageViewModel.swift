import Foundation
import WMF
import CocoaLumberjackSwift

final class TalkPageViewModel {

    // MARK: - Properties

    let pageType: TalkPageType
    let pageTitle: String
    let siteURL: URL
    private let dataController: TalkPageDataController

    // TODO: - Populate from data controller
    private(set) var headerTitle: String
    private(set) var headerDescription: String?
    private(set) var leadImageURL: URL?
    private(set) var coffeeRollText: String?
    private(set) var projectSourceImage: UIImage?
    private(set) var projectLanguage: String?
    
    static let leadImageSideLength = 98
    
    var theme: Theme = .light
    private(set) var topics: [TalkPageCellViewModel] = []

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

    func fetchTalkPage(completion: @escaping (Result<Void, Error>) -> Void) {
        dataController.fetchTalkPage { [weak self] result in
            switch result {
            case .success(let result):
                self?.populateHeaderData(articleSummary: result.articleSummary, items: result.items)
                self?.topics.removeAll()
                self?.populateCellData(topics: result.items)
                completion(.success(()))
            case .failure(let error):
                DDLogError("Failure fetching talk page: \(error)")
                completion(.failure(error))
                // TODO: Error handling
            }
        }
    }
    
    func postTopic(topicTitle: String, topicBody: String, completion: @escaping(Result<Void, Error>) -> Void) {
        dataController.postTopic(topicTitle: topicTitle, topicBody: topicBody, completion: completion)
    }
    
    // MARK: - Private
    
    private func populateHeaderData(articleSummary: WMFArticle?, items: [TalkPageItem]) {
        
        guard let languageCode = siteURL.wmf_languageCode else {
            return
        }
        
        headerTitle = pageTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode).title
        
        headerDescription = articleSummary?.wikidataDescription
        leadImageURL = articleSummary?.imageURL(forWidth: Self.leadImageSideLength)
        
        if let otherContent = items.first?.otherContent,
           !otherContent.isEmpty {
               coffeeRollText = items.first?.otherContent
        }
        
        projectLanguage = languageCode
        
        // TODO: Populate project source image
        projectSourceImage = nil
    }
    
    private func populateCellData(topics: [TalkPageItem]) {
        
        let cleanTopics = cleanTalkPageItems(items: topics)
        
        for topic in cleanTopics {
            
            guard let topicTitle = topic.html else {
                DDLogWarn("Missing topic title. Skipping topic.")
                continue
            }
            
            guard let firstReply = topic.replies.first,
                  let leadCommentViewModel = TalkPageCellCommentViewModel(text: firstReply.html, author: firstReply.author, authorTalkPageURL: "", timestamp: firstReply.timestamp, replyDepth: firstReply.level) else {
                DDLogWarn("Unable to parse lead comment. Skipping topic.")
                continue
            }
            
            let remainingReplies = Array(topic.replies.suffix(from: 1))
            
            let remainingCommentViewModels = remainingReplies.compactMap { TalkPageCellCommentViewModel(text: $0.html, author: $0.author, authorTalkPageURL: "", timestamp: $0.timestamp, replyDepth: $0.level) }
            
            let activeUsersCount = activeUsersCount(topic: topic)
            
            let topicViewModel = TalkPageCellViewModel(topicTitle: topicTitle, timestamp: firstReply.timestamp, leadComment: leadCommentViewModel, replies: remainingCommentViewModels, activeUsersCount: activeUsersCount)
            self.topics.append(topicViewModel)
        }
    }
    
    private func activeUsersCount(topic: TalkPageItem) -> String {
        var distinctUsers: Set<String> = []
        
        for item in topic.replies {
            if let author = item.author {
                distinctUsers.insert(author)
            }
        }
        
        return String(distinctUsers.count)
    }
}


// MARK: TalkPageItem Transform Methods

private extension TalkPageViewModel {

    /// Clean up talk page items so that we can more easily translate them into view models
    ///
    /// The talk page response returns items in a tree structure. To simplify the response to more closely match our design, we are flattening the items into one top-level list of topics, each with one level of replies. We also clear out any topics that we are not set up to display yet (unsigned topic content, topics without titles).
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
    
    func validTopLevelTopics(items: [TalkPageItem]) -> [TalkPageItem] {
        
        // Trim any topic item with missing replies (i.e. coffee roll, but also topics can have content without signatures)
        // Trim any topic item with a missing title (i.e. any threads that occur in the intro area before the first topic title)
        return items.filter { item in
            if (item.type == .heading && item.replies.isEmpty) ||
                (item.type == .heading && (item.html ?? "").isEmpty) {
                return false
            }
            
            return true
        }
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
