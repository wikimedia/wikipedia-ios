import Foundation


enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionConstructTitleFailure
    case unrecognizedHardcodedIdsForIntermediateCounts
    case failureToPopulateModelsFromDeepLink
    case failureToVerifyRevisionIDs
    case leadImageUnableToPullLanguageCode
    case leadImageUnableToGenerateInMemoryKey
    case leadImageNonMainNamespace
    case leadImageMissing
    
    var localizedDescription: String {
        return CommonStrings.genericErrorDescription
    }
}

class DiffController {
    
    enum RevisionDirection {
        case next
        case previous
    }
    
    let diffFetcher: DiffFetcher
    let pageHistoryFetcher: PageHistoryFetcher?
    let globalUserInfoFetcher: GlobalUserInfoFetcher
    let articleSummaryController: ArticleSummaryController
    let authenticationManager: WMFAuthenticationManager
    let siteURL: URL
    let type: DiffContainerViewModel.DiffType
    private weak var revisionRetrievingDelegate: DiffRevisionRetrieving?
    let transformer: DiffTransformer

    init(siteURL: URL, diffFetcher: DiffFetcher = DiffFetcher(), pageHistoryFetcher: PageHistoryFetcher?, revisionRetrievingDelegate: DiffRevisionRetrieving?, type: DiffContainerViewModel.DiffType, articleSummaryController: ArticleSummaryController, authenticationManager: WMFAuthenticationManager) {

        self.diffFetcher = diffFetcher
        self.pageHistoryFetcher = pageHistoryFetcher
        self.articleSummaryController = articleSummaryController
        self.globalUserInfoFetcher = GlobalUserInfoFetcher()
        self.siteURL = siteURL
        self.revisionRetrievingDelegate = revisionRetrievingDelegate
        self.type = type
        self.transformer = DiffTransformer(type: type, siteURL: siteURL)
        self.authenticationManager = authenticationManager
    }
    
    func fetchEditCount(guiUser: String, completion: @escaping ((Result<Int, Error>) -> Void)) {

        globalUserInfoFetcher.fetchEditCount(guiUser: guiUser, siteURL: siteURL, completion: completion)
    }
    
    func fetchLeadImageURL(siteURL: URL, articleTitle: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let languageCode = siteURL.wmf_languageCode else {
            completion(.failure(DiffError.leadImageUnableToPullLanguageCode))
            return
        }
        
        let namespaceAndTitle = articleTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        guard namespaceAndTitle.namespace == .main else {
            completion(.failure(DiffError.leadImageNonMainNamespace))
            return
        }
        
        guard let mainNamespacePageURL = siteURL.wmf_URL(withTitle: namespaceAndTitle.title),
              let inMemoryKey = mainNamespacePageURL.wmf_inMemoryKey else {
            completion(.failure(DiffError.leadImageUnableToGenerateInMemoryKey))
            return
        }
        
        articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: inMemoryKey) { article, error in
            DispatchQueue.main.async {
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let imageSideLength = 80
                guard let leadImageURL = article?.imageURL(forWidth: imageSideLength * Int(UIScreen.main.scale)) else {
                    completion(.failure(DiffError.leadImageMissing))
                    return
                }
                
                completion(.success(leadImageURL))
            }
        }
    }
    
    func fetchFirstRevisionModel(articleTitle: String, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) {

        guard let articleTitle = articleTitle.normalizedPageTitle else {
            completion(.failure(DiffError.fetchRevisionConstructTitleFailure))
            return
        }
        
        diffFetcher.fetchFirstRevisionModel(siteURL: siteURL, articleTitle: articleTitle, completion: completion)
    }
    
    struct DeepLinkModelsResponse {
        let from: WMFPageHistoryRevision?
        let to: WMFPageHistoryRevision?
        let first: WMFPageHistoryRevision
        let articleTitle: String
    }
    
    func populateModelsFromDeepLink(fromRevisionID: Int?, toRevisionID: Int?, articleTitle: String?, completion: @escaping ((Result<DeepLinkModelsResponse, Error>) -> Void)) {
        
        if let articleTitle = articleTitle {
            populateModelsFromDeepLink(fromRevisionID: fromRevisionID, toRevisionID: toRevisionID, articleTitle: articleTitle, completion: completion)
            return
        }
        
        let maybeRevisionID = toRevisionID ?? fromRevisionID
        
        guard let revisionID = maybeRevisionID else {
                completion(.failure(DiffError.failureToVerifyRevisionIDs))
                return
        }
        
        diffFetcher.fetchArticleTitle(siteURL: siteURL, revisionID: revisionID) { (result) in
            switch result {
            case .success(let title):
                
                self.populateModelsFromDeepLink(fromRevisionID: fromRevisionID, toRevisionID: toRevisionID, articleTitle: title, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    private func populateModelsFromDeepLink(fromRevisionID: Int?, toRevisionID: Int?, articleTitle: String, completion: @escaping ((Result<DeepLinkModelsResponse, Error>) -> Void)) {
        guard let articleTitle = articleTitle.normalizedPageTitle else {
            completion(.failure(DiffError.fetchRevisionConstructTitleFailure))
            return
        }
        
        var fromResponse: WMFPageHistoryRevision?
        var toResponse: WMFPageHistoryRevision?
        var firstResponse: WMFPageHistoryRevision?
        
        let group = DispatchGroup()
        
        if let fromRevisionID = fromRevisionID {
            
            group.enter()
            let fromRequest = DiffFetcher.FetchRevisionModelRequest.populateModel(revisionID: fromRevisionID)
            diffFetcher.fetchRevisionModel(siteURL, articleTitle: articleTitle, request: fromRequest) { (result) in
                switch result {
                case .success(let fetchResponse):
                    fromResponse = fetchResponse
                case .failure:
                    break
                }
                group.leave()
            }
        }
        
        if let toRevisionID = toRevisionID {
            group.enter()
            let toRequest = DiffFetcher.FetchRevisionModelRequest.populateModel(revisionID: toRevisionID)
            diffFetcher.fetchRevisionModel(siteURL, articleTitle: articleTitle, request: toRequest) { (result) in
                switch result {
                case .success(let fetchResponse):
                    toResponse = fetchResponse
                case .failure:
                    break
                }
                group.leave()
            }
        }
        
        group.enter()
        diffFetcher.fetchFirstRevisionModel(siteURL: siteURL, articleTitle: articleTitle) { (result) in
            switch result {
            case .success(let fetchResponse):
                firstResponse = fetchResponse
            case .failure:
                break
            }
            group.leave()
        }
            
            group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            guard let firstResponse = firstResponse,
                fromResponse != nil || toResponse != nil else {
                    completion(.failure(DiffError.failureToPopulateModelsFromDeepLink))
                    return
            }
            
            let response = DeepLinkModelsResponse(from: fromResponse, to: toResponse, first: firstResponse, articleTitle: articleTitle)
            completion(.success(response))
        }
    }
    
    func fetchAdjacentRevisionModel(sourceRevision: WMFPageHistoryRevision, direction: RevisionDirection, articleTitle: String, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) {
        
        if let revisionRetrievingDelegate = revisionRetrievingDelegate {
            
            // optimization - first try to grab a revision we might already have in memory from the revisionRetrievingDelegate
            switch direction {
            case .next:
                if let nextRevision = revisionRetrievingDelegate.retrieveNextRevision(with: sourceRevision) {
                    completion(.success(nextRevision))
                    return
                }
            case .previous:
                if let previousRevision = revisionRetrievingDelegate.retrievePreviousRevision(with: sourceRevision) {
                    completion(.success(previousRevision))
                    return
                }
            }
        }

        let direction: DiffFetcher.FetchRevisionModelRequestDirection = direction == .previous ? .older : .newer
        
        let request = DiffFetcher.FetchRevisionModelRequest.adjacent(sourceRevision: sourceRevision, direction: direction)
        
        diffFetcher.fetchRevisionModel(siteURL, articleTitle: articleTitle, request: request) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchFirstRevisionDiff(revisionId: Int, siteURL: URL, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {
        
        diffFetcher.fetchWikitext(siteURL: siteURL, revisionId: revisionId) { (result) in
            switch result {
            case .success(let wikitext):
                do {
                    let viewModels = try self.transformer.firstRevisionViewModels(from: wikitext, theme: theme, traitCollection: traitCollection)

                    completion(.success(viewModels))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchDiff(fromRevisionId: Int, toRevisionId: Int, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {

//        let queue = DispatchQueue.global(qos: .userInitiated)
//
//        queue.async { [weak self] in
//
//            guard let self = self else { return }
//
//            do {
//
//            let url = Bundle.main.url(forResource: "DiffResponse", withExtension: "json")!
//            let data = try Data(contentsOf: url)
//            let diffResponse = try JSONDecoder().decode(DiffResponse.self, from: data)
//
//            
//                do {
//                    let viewModels = try self.transformer.viewModels(from: diffResponse, theme: theme, traitCollection: traitCollection)
//
//                    completion(.success(viewModels))
//                } catch (let error) {
//                    completion(.failure(error))
//                }
//                
//
//            } catch (let error) {
//                completion(.failure(error))
//            }
//        }
        
        diffFetcher.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) { [weak self] (result) in

            guard let self = self else { return }

            switch result {
            case .success(let diffResponse):

                do {
                    let viewModels = try self.transformer.viewModels(from: diffResponse, theme: theme, traitCollection: traitCollection)

                    completion(.success(viewModels))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}
