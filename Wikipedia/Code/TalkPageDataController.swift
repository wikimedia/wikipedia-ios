import Foundation

/// Class that coordinates network fetches for talk pages.
/// Leans on file persistence for offline mode as-needed.
class TalkPageDataController {
    
    private let pageTitle: String
    private let siteURL: URL
    private let talkPageFetcher = TalkPageFetcher()
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    func fetchTalkPageContent(completion: @escaping (Result<[TalkPageItem], Error>) -> Void) {
        talkPageFetcher.fetchTalkPageContent(talkPageTitle: pageTitle, siteURL: siteURL, completion: completion)
    }
    
    func postReply(commentId: String, comment: String, completion: @escaping(Result<Void, Error>) -> Void) {
        talkPageFetcher.postReply(talkPageTitle: pageTitle, siteURL: siteURL, commentId: commentId, comment: comment, completion: completion)
    }
    
    func postTopic(topicTitle: String, topicBody: String, completion: @escaping(Result<Void, Error>) -> Void) {
        talkPageFetcher.postTopic(talkPageTitle: pageTitle, siteURL: siteURL, topicTitle: topicTitle, topicBody: topicBody, completion: completion)
    }
    
    func subscribeToTopic(topicName: String, shouldSubscribe: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        talkPageFetcher.subscribeToTopic(talkPageTitle: pageTitle, siteURL: siteURL, topic: topicName, shouldSubscribe: shouldSubscribe, completion: completion)
    }
}
