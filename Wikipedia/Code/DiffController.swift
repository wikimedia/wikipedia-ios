
import Foundation


enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionIDFailure
    case noPreviousRevisionID
    case unrecognizedHardcodedIdsForIntermediateCounts
    
    var localizedDescription: String {
        return CommonStrings.genericErrorDescription
    }
}

class DiffController {
    
    let diffFetcher: DiffFetcher
    let revisionFetcher: WMFArticleRevisionFetcher
    let globalUserInfoFetcher: GlobalUserInfoFetcher
    let diffThanker: DiffThanker
    let articleTitle: String
    let siteURL: URL
    let type: DiffContainerViewModel.DiffType
    let transformer: DiffTransformer
    
    init(siteURL: URL, articleTitle: String, diffFetcher: DiffFetcher = DiffFetcher(), revisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), globalUserInfoFetcher: GlobalUserInfoFetcher = GlobalUserInfoFetcher(), diffThanker: DiffThanker = DiffThanker(), type: DiffContainerViewModel.DiffType, transformer: DiffTransformer? = nil) {
        self.diffFetcher = diffFetcher
        self.revisionFetcher = revisionFetcher
        self.globalUserInfoFetcher = globalUserInfoFetcher
        self.diffThanker = diffThanker
        self.articleTitle = articleTitle
        self.siteURL = siteURL
        self.type = type
        
        if let transformer = transformer {
            self.transformer = transformer
        } else {
            self.transformer = DiffTransformer(type: type, siteURL: siteURL)
        }
    }
    
    func fetchIntermediateCounts(fromRevisionId: Int, toRevisionId: Int, completion: @escaping ((Result<(revision: Int, user: Int), Error>) -> Void)) {
        
        //tonitodo: intermediate counts endpoint when ready
        DispatchQueue.global(qos: .userInitiated).async {
            
            if fromRevisionId == 392751 && toRevisionId == 399777 {
                completion(.success((revision: 60, user: 12)))
            }
            
            completion(.failure(DiffError.unrecognizedHardcodedIdsForIntermediateCounts))
        }
    }
    
    func fetchEditCount(guiUser: String, completion: @escaping ((Result<Int, Error>) -> Void)) {
        globalUserInfoFetcher.fetchEditCount(guiUser: guiUser, siteURL: siteURL, completion: completion)
    }
    
    func fetchDiff(fromRevisionId: Int?, toRevisionId: Int, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {
        
        if let fromRevisionId = fromRevisionId {
            fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, theme: theme, traitCollection: traitCollection, completion: completion)
            return
        }
        
        fetchSingleNextRevision(toRevisionId: toRevisionId) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let fromRevisionId):
                self?.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, theme: theme, traitCollection: traitCollection, completion: completion)
            }
        }
    }
    
    func thankRevisionAuthor(toRevisionId: Int, completion: @escaping ((Result<DiffThankerResult, Error>) -> Void)) {
        diffThanker.thank(siteURL: siteURL, rev: toRevisionId, completion: completion)
    }
    
    private func fetchSingleNextRevision(toRevisionId: Int, completion: @escaping ((Result<Int, Error>) -> Void)) {
        
        guard let articleTitle = (articleTitle as NSString).wmf_normalizedPageTitle(),
            let articleURL = siteURL.wmf_URL(withPath: "/wiki/\(articleTitle)", isMobile: true) else {
            return
        }
        
        revisionFetcher.fetchLatestRevisions(forArticleURL: articleURL, resultLimit: 2, startingWithRevision: NSNumber(value: toRevisionId), endingWithRevision: nil, failure: { (error) in
            completion(.failure(error))
        }) { (result) in
            
            let queryResults = (result as? [WMFRevisionQueryResults])?.first ?? (result as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.last?.revisionId.intValue else {
                completion(.failure(DiffError.fetchRevisionIDFailure))
                return
            }
            
            if lastRevisionId == toRevisionId {
                completion(.failure(DiffError.noPreviousRevisionID))
                return
            }
            
            completion(.success(lastRevisionId))
            
        }
    }
    
    private func fetchDiff(fromRevisionId: Int, toRevisionId: Int, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {

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
