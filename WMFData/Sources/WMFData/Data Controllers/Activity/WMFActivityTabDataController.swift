import Foundation
import UIKit
import CoreData

public enum WMFActivityDataControllerError: Error {
    case dateFailure
}

public class WMFActivityDataController: NSObject {
    
    public let coreDataStore: WMFCoreDataStore
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    public var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    public var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
    }
    
    public struct Activity {
        public let readCount: Int
        public let savedCount: Int
        public let editedCount: Int?
    }
    
    public func fetchAllStuff(username: String, project: WMFProject?) async throws -> Activity {
        let project = project ?? WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        let readCount: Int = try await fetchReadCount() ?? 0
        let savedCount: Int = try await fetchSavedCount() ?? 0
        let editedCount = try await fetchEditCount(username: username, project: project)
        
        return Activity(readCount: readCount, savedCount: savedCount, editedCount: editedCount)
    }
    
    private func fetchReadCount() async throws -> Int? {
        
        let now = Date()

        guard let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) else {
            throw WMFActivityDataControllerError.dateFailure
        }
        
        
        let legacyPageViews = try await legacyPageViewsDataDelegate?.getLegacyPageViews(from: oneWeekAgo, to: now)
        return legacyPageViews?.count
    }
    
    
    private func fetchSavedCount() async throws -> Int? {
        
        let now = Date()

        guard let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) else {
            throw WMFActivityDataControllerError.dateFailure
        }
        
        let savedArticlesData = await self.savedSlideDataDelegate?.getSavedArticleSlideData(from: oneWeekAgo, to: now)
        return savedArticlesData?.savedArticlesCount
    }
    
    private func fetchEditCount(username: String, project: WMFProject?) async throws -> Int {
        
        let now = Date()
        let formatter = DateFormatter.mediaWikiAPIDateFormatter
        let nowString = formatter.string(from: now)
        
        guard let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) else {
            throw WMFActivityDataControllerError.dateFailure
        }
        
        let oneWeekAgoString = formatter.string(from: oneWeekAgo)
        
        let (edits, _) = try await fetchUserContributionsCount(username: username, project: project, startDate: oneWeekAgoString, endDate: nowString)
        
        return edits
    }
    
    public func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String) async throws -> (Int, Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchUserContributionsCount(username: username, project: project, startDate: startDate, endDate: endDate) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        // We have to switch the dates here before sending into the API.
        // It is expected that this method's startDate parameter is chronologically earlier than endDate. This is how the remote feature config is set up.
        // The User Contributions API expects ucend to be chronologically earlier than ucstart, because it pages backwards so that the most recent edits appear on the first page.
        let ucStartDate = endDate
        let ucEndDate = startDate
        
        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "list": "usercontribs",
            "formatversion": "2",
            "uclimit": "500",
            "ucstart": ucStartDate,
            "ucend": ucEndDate,
            "ucuser": username,
            "ucnamespace": "0",
            "ucprop": "ids|title|timestamp|tags|flags"
        ]
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
            switch result {
            case .success(let response):
                guard let query = response.query else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }
                
                let editCount = query.usercontribs.count
                
                let hasMoreEdits = response.continue?.uccontinue != nil
                
                completion(.success((editCount, hasMoreEdits)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    struct UserContributionsAPIResponse: Codable {
        let batchcomplete: Bool?
        let `continue`: ContinueData?
        let query: UserContributionsQuery?

        struct ContinueData: Codable {
            let uccontinue: String?
        }

        struct UserContributionsQuery: Codable {
            let usercontribs: [UserContribution]
        }
    }

    struct UserContribution: Codable {
        let userid: Int
        let user: String
        let pageid: Int
        let revid: Int
        let parentid: Int
        let ns: Int
        let title: String
        let timestamp: String
        let isNew: Bool
        let isMinor: Bool
        let isTop: Bool
        let tags: [String]

        enum CodingKeys: String, CodingKey {
            case userid, user, pageid, revid, parentid, ns, title, timestamp, tags
            case isNew = "new"
            case isMinor = "minor"
            case isTop = "top"
        }
    }
    
    struct UserStats: Decodable {
        let version: Int
        let userId: Int
        let userName: String
        let receivedThanksCount: Int
        let editCountByNamespace: [String: Int]
        let editCountByDay: [String: Int]
        let editCountByTaskType: [String: Int]
        let totalUserEditCount: Int
        let revertedEditCount: Int
        let newcomerTaskEditCount: Int
        let lastEditTimestamp: Int
        let generatedAt: Int
        let longestEditingStreak: LongestEditingStreak
        let totalEditsCount: Int
        let dailyTotalViews: [String: Int]
        let recentEditsWithoutPageviews: [String]
        let topViewedArticles: [String: TopViewedArticle]
        let topViewedArticlesCount: Int
        let totalPageviewsCount: Int
    }

    struct LongestEditingStreak: Decodable {
        let datePeriod: DatePeriod
        let totalEditCountForPeriod: Int
    }

    struct DatePeriod: Decodable {
        let start: String
        let end: String
        let days: Int
    }

    struct TopViewedArticle: Decodable {
        let imageUrl: String
        let firstEditDate: String
        let newestEdit: String
        let views: [String: Int]
        let viewsCount: Int
        let pageviewsUrl: String
    }
}
