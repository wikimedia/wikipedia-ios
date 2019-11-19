
import Foundation


enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionConstructTitleFailure
    case unrecognizedHardcodedIdsForIntermediateCounts
    
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
    let articleTitle: String
    let siteURL: URL
    let type: DiffContainerViewModel.DiffType
    private weak var revisionRetrievingDelegate: DiffRevisionRetrieving?
    let transformer: DiffTransformer

    init(siteURL: URL, articleTitle: String, diffFetcher: DiffFetcher = DiffFetcher(), pageHistoryFetcher: PageHistoryFetcher?, globalUserInfoFetcher: GlobalUserInfoFetcher = GlobalUserInfoFetcher(), diffThanker: DiffThanker = DiffThanker(), revisionRetrievingDelegate: DiffRevisionRetrieving?, type: DiffContainerViewModel.DiffType, transformer: DiffTransformer? = nil) {

        self.diffFetcher = diffFetcher
        self.pageHistoryFetcher = pageHistoryFetcher
        self.globalUserInfoFetcher = globalUserInfoFetcher
        self.diffThanker = diffThanker
        self.articleTitle = articleTitle
        self.siteURL = siteURL
        self.revisionRetrievingDelegate = revisionRetrievingDelegate
        self.type = type
        
        if let transformer = transformer {
            self.transformer = transformer
        } else {
            self.transformer = DiffTransformer(type: type, siteURL: siteURL)
        }
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
        
        //failing that try fetching revision from API
        guard let articleTitle = (articleTitle as NSString).wmf_normalizedPageTitle() else {
            completion(.failure(DiffError.fetchRevisionConstructTitleFailure))
            return
        }

        let direction: DiffFetcher.SingleRevisionRequestDirection = direction == .previous ? .older : .newer
        
        diffFetcher.fetchSingleRevisionInfo(siteURL, sourceRevision: sourceRevision, title: articleTitle, direction: direction, completion: completion)
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
