import Foundation

public final class WMFArticleDataController {
    
    private let mediaWikiService: WMFService?
    
    public init(mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.mediaWikiService = mediaWikiService
    }
    
    public struct ArticleInfoRequest {
        let needsWatchedStatus: Bool
        let needsRollbackRights: Bool
        let needsCategories: Bool
        let needsUserInfo: Bool

        public init(needsWatchedStatus: Bool, needsRollbackRights: Bool, needsCategories: Bool, needsUserInfo: Bool = false) throws {
            self.needsWatchedStatus = needsWatchedStatus
            self.needsRollbackRights = needsRollbackRights
            self.needsCategories = needsCategories
            self.needsUserInfo = needsUserInfo

            guard needsWatchedStatus == true ||
                    needsRollbackRights == true ||
                    needsCategories == true ||
                    needsUserInfo == true else {
                throw WMFServiceError.invalidRequest
            }
        }
    }
    
    struct ArticleInfoResponse: Codable {

        struct Query: Codable {

            struct Page: Codable {
                
                struct Category: Codable {
                    let ns: Int
                    let title: String
                }
                
                let title: String
                let watched: Bool?
                let watchlistexpiry: String?
                let categories: [Category]?
            }

            struct UserInfo: Codable {
                let id: Int?
                let name: String
                let anon: Bool?
                let temp: Bool?
                let rights: [String]?
                let groups: [String]?
                let editcount: UInt64?
                let blockid: UInt64?
                let blockpartial: Bool?
                let registrationdate: String?
            }

            struct GlobalUserInfo: Codable {
                let id: Int?
            }

            let pages: [Page]
            let userinfo: UserInfo?
            let globaluserinfo: GlobalUserInfo?
        }

        let query: Query
    }

    /// Info about the current user on the article's wiki, as returned with the article info request.
    public struct WMFArticleUserInfo {
        public let userID: Int
        public let globalUserID: Int?
        public let name: String
        public let groups: [String]
        public let editCount: UInt64
        public let isBlocked: Bool
        public let isIP: Bool
        public let isTemp: Bool
        public let registrationDateString: String?
    }

    public struct WMFArticleInfoResponse {
        public let watched: Bool
        public let watchlistExpiry: Date?
        public let userHasRollbackRights: Bool?
        public let categories: [String]
        public let userInfo: WMFArticleUserInfo?
    }

    
    /// Fetches possible info needed from MediaWiki for a particular article. Watch status, user rollback rights, categories. The idea here is to fetch all we need for article display in a single call so the app only needs to make an API call to MediaWiki once upon article view.
    /// - Parameters:
    ///   - title: Title of the article
    ///   - project: Project the article belongs to (EN Wiki, etc)
    ///   - request: Request struct to fetch certain pieces of data. So far can support watchlist status and user rollback rights.
    ///   - completion: Completion block called when API has completed
    public func fetchArticleInfo(title: String, project: WMFProject, request: ArticleInfoRequest, completion: @escaping @Sendable (Result<WMFArticleInfoResponse, Error>) -> Void) {
         
        guard let mediaWikiService else {
             completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
             return
         }
        

         var parameters = [
                     "action": "query",
                     "titles": title,
                     "errorsuselocal": "1",
                     "errorformat": "html",
                     "format": "json",
                     "formatversion": "2"
                 ]
        
        if request.needsWatchedStatus {
            parameters["prop"] = "info"
            parameters["inprop"] = "watched"
        }
        
        if request.needsCategories {
            if request.needsWatchedStatus {
                parameters["prop"] = "info|categories"
            } else {
                parameters["prop"] = "categories"
            }
            
            parameters["clshow"] = "!hidden"
            parameters["cllimit"] = "500"
        }

        if request.needsUserInfo {
            parameters["meta"] = "userinfo|globaluserinfo"
            parameters["uiprop"] = "rights|groups|blockinfo|editcount|registrationdate"
        } else if request.needsRollbackRights {
            parameters["meta"] = "userinfo"
            parameters["uiprop"] = "rights"
        }

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             return
         }

         let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        mediaWikiService.performDecodableGET(request: request) { (result: Result<ArticleInfoResponse, Error>) in
             switch result {
             case .success(let response):

                guard let firstPage = response.query.pages.first else {
                 completion(.failure(WMFDataControllerError.unexpectedResponse))
                 return
                }

                let watched = firstPage.watched ?? false
                let userHasRollbackRights = response.query.userinfo?.rights?.contains("rollback")
                 
                var watchlistExpiry: Date? = nil
                if let watchlistExpiryString = firstPage.watchlistexpiry {
                  watchlistExpiry = DateFormatter.mediaWikiAPIDateFormatter.date(from: watchlistExpiryString)
                }
                 
                 var categoryTitles: [String] = []
                 if let responseCategories = firstPage.categories {
                    for category in responseCategories {
                        categoryTitles.append(category.title)
                    }
                 }

                 var articleUserInfo: WMFArticleUserInfo? = nil
                 if let userinfo = response.query.userinfo, let userID = userinfo.id {
                     let blockPartial = userinfo.blockpartial ?? false
                     let isBlocked = userinfo.blockid != nil && !blockPartial
                     articleUserInfo = WMFArticleUserInfo(
                         userID: userID,
                         globalUserID: response.query.globaluserinfo?.id,
                         name: userinfo.name,
                         groups: userinfo.groups ?? [],
                         editCount: userinfo.editcount ?? 0,
                         isBlocked: isBlocked,
                         isIP: userinfo.anon ?? false,
                         isTemp: userinfo.temp ?? false,
                         registrationDateString: userinfo.registrationdate
                     )
                 }

                 let status = WMFArticleInfoResponse(watched: watched, watchlistExpiry: watchlistExpiry, userHasRollbackRights: userHasRollbackRights, categories: categoryTitles, userInfo: articleUserInfo)
                 completion(.success(status))
             case .failure(let error):
                 completion(.failure(WMFDataControllerError.serviceError(error)))
             }
         }
     }
}
