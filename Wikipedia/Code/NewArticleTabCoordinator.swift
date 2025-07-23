import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    private let fetcher: RelatedSearchFetcher

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fetcher: RelatedSearchFetcher = RelatedSearchFetcher()) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fetcher = fetcher
    }

    var seed: WMFArticle?
    var related: [WMFArticle?] = []
    private var seenSeedKeys = Set<String>()

    private let contentSource = WMFRelatedPagesContentSource()

    func loadNextBatch(
      completion: @escaping (WMFArticle?, [WMFArticle?]) -> Void
    ) {
        let moc = dataStore.feedImportContext

        // Retrieve significantly viewed
        moc.perform {
            let req: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            let base = NSPredicate(format:
                "isExcludedFromFeed == NO AND (wasSignificantlyViewed == YES OR savedDate != nil)"
            )
            if !self.seenSeedKeys.isEmpty {
                let exclude = NSPredicate(format: "NOT (key IN %@)", self.seenSeedKeys)
                req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [base, exclude])
            } else {
                req.predicate = base
            }
            let total = (try? moc.count(for: req)) ?? 0
            if total == 0 {
                self.seenSeedKeys.removeAll()
            }
            req.fetchOffset = Int.random(in: 0..<max(total,1))
            req.fetchLimit  = 1

            guard let picked = (try? moc.fetch(req))?.first,
                  let seedURL = picked.url else {
                DispatchQueue.main.async {
                    self.seed    = nil
                    self.related = []
                    completion(nil, [])
                }
                return
            }

            // remember used articles
            if let key = picked.key {
                self.seenSeedKeys.insert(key)
            }

            DispatchQueue.main.async {
                self.seed = picked
            }

            DispatchQueue.main.async {
                self.fetcher.fetchRelatedArticles(forArticleWithURL: seedURL) { error, summariesByKey in
                    let summaries = summariesByKey?.values.prefix(3).map { $0 } ?? []
                    moc.perform {
                        do {

                            guard let summariesByKey else {
                                completion(picked, [])
                                return
                            }

                            let articlesByKey =  try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summariesByKey)


                            let orderedKeys = Array(summariesByKey.keys)
                            let relatedArticles: [WMFArticle] = orderedKeys.compactMap {
                                articlesByKey[$0]
                            }

                            DispatchQueue.main.async {
                                completion(picked, relatedArticles)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion(picked, [])
                            }
                        }
                    }

                }
            }

        }
    }

    @discardableResult
    func start() -> Bool {

        loadNextBatch { seed, related in
            print("====== SEED: \(seed?.displayTitle ?? "nil"), RELATED: \(related)")
            self.seed    = seed
            self.related = related

        }

        let viewModel = WMFNewArticleTabViewModel(title: CommonStrings.newTab)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

}
