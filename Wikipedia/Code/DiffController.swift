
import Foundation


enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionConstructTitleFailure
    case unrecognizedHardcodedIdsForIntermediateCounts
    case failureToPopulateModelsFromDeepLink
    
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
    let diffThanker: DiffThanker
    let siteURL: URL
    let type: DiffContainerViewModel.DiffType
    private weak var revisionRetrievingDelegate: DiffRevisionRetrieving?
    let transformer: DiffTransformer

    init(siteURL: URL, diffFetcher: DiffFetcher = DiffFetcher(), pageHistoryFetcher: PageHistoryFetcher?, revisionRetrievingDelegate: DiffRevisionRetrieving?, type: DiffContainerViewModel.DiffType) {

        self.diffFetcher = diffFetcher
        self.pageHistoryFetcher = pageHistoryFetcher
        self.globalUserInfoFetcher = GlobalUserInfoFetcher()
        self.diffThanker = DiffThanker()
        self.siteURL = siteURL
        self.revisionRetrievingDelegate = revisionRetrievingDelegate
        self.type = type
        self.transformer = DiffTransformer(type: type, siteURL: siteURL)
    }
    
    func fetchEditCount(guiUser: String, completion: @escaping ((Result<Int, Error>) -> Void)) {

        globalUserInfoFetcher.fetchEditCount(guiUser: guiUser, siteURL: siteURL, completion: completion)
    }

    func fetchIntermediateCounts(for pageTitle: String, pageURL: URL, from fromRevisionID: Int , to toRevisionID: Int, completion: @escaping (Result<EditCountsGroupedByType, Error>) -> Void) {
        pageHistoryFetcher?.fetchEditCounts(.edits, .editors, for: pageTitle, pageURL: pageURL, from: fromRevisionID, to: toRevisionID, completion: completion)
    }
    
    func thankRevisionAuthor(toRevisionId: Int, completion: @escaping ((Result<DiffThankerResult, Error>) -> Void)) {
        diffThanker.thank(siteURL: siteURL, rev: toRevisionId, completion: completion)
    }
    
    func fetchFirstRevision(articleTitle: String, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) {
        //failing that try fetching revision from API
        guard let articleTitle = (articleTitle as NSString).wmf_normalizedPageTitle() else {
            completion(.failure(DiffError.fetchRevisionConstructTitleFailure))
            return
        }
        
        diffFetcher.fetchFirstRevision(siteURL: siteURL, articleTitle: articleTitle, completion: completion)
    }
    
    func populateFromDeepLink(toRevisionID: Int, fromRevisionID: Int?, completion: @escaping ((Result<(DiffFetcher.SingleRevisionResponse?, DiffFetcher.SingleRevisionResponse), Error>) -> Void)) {
        
        if let fromRevisionID = fromRevisionID {
            
            var fromResponse: DiffFetcher.SingleRevisionResponse?
            var toResponse: DiffFetcher.SingleRevisionResponse?
            
            let group = DispatchGroup()
            
            group.enter()
            
            let fromRequest = DiffFetcher.SingleRevisionRequest.populateModel(revisionID: fromRevisionID)
            diffFetcher.fetchSingleRevisionInfo(siteURL, request: fromRequest) { (result) in
                switch result {
                case .success(let fetchResponse):
                    fromResponse = fetchResponse
                case .failure:
                    break
                }
                group.leave()
            }
            
            let toRequest = DiffFetcher.SingleRevisionRequest.populateModel(revisionID: toRevisionID)
            diffFetcher.fetchSingleRevisionInfo(siteURL, request: toRequest) { (result) in
                switch result {
                case .success(let fetchResponse):
                    toResponse = fetchResponse
                case .failure:
                    break
                }
                group.leave()
            }
            
            group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                guard let toResponse = toResponse,
                    let fromResponse = fromResponse else {
                        completion(.failure(DiffError.failureToPopulateModelsFromDeepLink))
                        return
                }
                
                completion(.success((fromResponse, toResponse)))
            }
            
            return
        } else {
            
            let toRequest = DiffFetcher.SingleRevisionRequest.populateModel(revisionID: toRevisionID)
            diffFetcher.fetchSingleRevisionInfo(siteURL, request: toRequest) { (result) in
                switch result {
                case .success(let fetchResponse):
                    completion(.success((nil, fetchResponse)))
                case .failure:
                    completion(.failure(DiffError.failureToPopulateModelsFromDeepLink))
                }
            }
        }
    }
    
    func fetchRevision(sourceRevision: WMFPageHistoryRevision, direction: RevisionDirection, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) {
        
        if let revisionRetrievingDelegate = revisionRetrievingDelegate {
            
            //optimization - first try to grab a revision we might already have in memory from the revisionRetrievingDelegate
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

        let direction: DiffFetcher.SingleRevisionRequestDirection = direction == .previous ? .older : .newer
        
        let request = DiffFetcher.SingleRevisionRequest.prevOrNext(sourceRevision: sourceRevision, direction: direction)
        
        diffFetcher.fetchSingleRevisionInfo(siteURL, request: request) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response.model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchFirstRevision(revisionId: Int, siteURL: URL, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {
        
        diffFetcher.fetchWikitext(siteURL: siteURL, revisionId: revisionId) { (result) in
            switch result {
            case .success(let wikitext):
                do {
                    let viewModels = try self.transformer.firstRevisionViewModels(from: wikitext, theme: theme, traitCollection: traitCollection)

                    completion(.success(viewModels))
                } catch (let error) {
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
                } catch (let error) {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}
