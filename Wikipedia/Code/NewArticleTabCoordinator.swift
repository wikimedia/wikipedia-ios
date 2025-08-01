import UIKit
import WMF
import WMFComponents
import WMFData

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
    var related: [WMFArticle] = []
    private var seenSeedKeys = Set<String>()

    private let contentSource = WMFRelatedPagesContentSource()

    func loadNextBatch(completion: @escaping (WMFArticle?, [WMFArticle]) -> Void) {
        let moc = dataStore.feedImportContext

        // Get significantly read article
        var pickedSeed: WMFArticle?
        var seedURL:    URL?
        moc.performAndWait {
            let req: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            let base = NSPredicate(format:"isExcludedFromFeed == NO AND (wasSignificantlyViewed == YES OR savedDate != nil)")
            // Remember used articles
            if !self.seenSeedKeys.isEmpty {
                let exclude = NSPredicate(format: "NOT (key IN %@)", self.seenSeedKeys)
                req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [base, exclude])
            } else {
                req.predicate = base
            }
            // If we went through all articles, start again
            let total = (try? moc.count(for: req)) ?? 0
            if total == 0 {
                self.seenSeedKeys.removeAll()
            }
            req.fetchOffset = Int.random(in: 0..<max(total,1))
            req.fetchLimit  = 1

            if let seed = (try? moc.fetch(req))?.first {
                pickedSeed = seed
                seedURL    = seed.url
                if let key = seed.key {
                    self.seenSeedKeys.insert(key)
                }
            }
        }

        DispatchQueue.main.async {
            self.seed = pickedSeed
        }
        guard let seed = pickedSeed, let url = seedURL else {
            return DispatchQueue.main.async {
                self.related = []
                completion(nil, [])
            }
        }

        // Fetch related articles
        fetcher.fetchRelatedArticles(forArticleWithURL: url) { error, summariesByKey in

            // Transfrom ArticleSummary into Article
            moc.perform {
                do {
                    // guard against nil dictionary
                    guard let summariesByKey = summariesByKey else {
                        DispatchQueue.main.async {
                            completion(seed, [])
                        }
                        return
                    }

                    // take the first 3
                    let top3Summaries = Array(summariesByKey)
                        .prefix(3)
                        .reduce(into: [WMFInMemoryURLKey: ArticleSummary]()) { result, pair in
                            result[pair.key] = pair.value
                        }

                    let articlesByKey = try moc.wmf_createOrUpdateArticleSummmaries(
                        withSummaryResponses: top3Summaries
                    )

                    // preserve the original order
                    let orderedKeys = Array(top3Summaries.keys)
                    let relatedArticles: [WMFArticle] = orderedKeys.compactMap {
                        articlesByKey[$0]
                    }
                    DispatchQueue.main.async {
                        self.related = relatedArticles
                        completion(seed, relatedArticles)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(seed, [])
                    }
                }
            }
        }
    }

    @discardableResult
    func start() -> Bool {

        loadNextBatch { seed, related in
            var becauseVM: WMFBecauseYouReadViewModel? = nil
            if let seed {
                let seedRecord = seed.toHistoryRecord()
                let relatedRecords = related.compactMap { article in
                    article.toHistoryRecord()
                }

                if !relatedRecords.isEmpty {
                    let onTapArticleAction: WMFBecauseYouReadViewModel.OnRecordTapAction = { [weak self] historyItem in
                        guard let self else {
                            return
                        }

                        self.tappedArticle(historyItem)
                    }

                    becauseVM = WMFBecauseYouReadViewModel(
                        becauseYouReadTitle: CommonStrings.relatedPagesTitle,
                        openButtonTitle: CommonStrings.articleTabsOpen,
                        seedArticle: seedRecord,
                        relatedArticles: relatedRecords
                    )
                    becauseVM?.onTapArticle = onTapArticleAction

                }
            }

            let viewModel = WMFNewArticleTabViewModel(
                title: CommonStrings.newTab,
                becauseYouReadViewModel: becauseVM
            )
            let vc = WMFNewArticleTabViewController(
                dataStore: self.dataStore,
                theme: self.theme,
                viewModel: viewModel
            )
            
            self.navigationController.pushViewController(vc, animated: true)
        }
        return true
    }

    func tappedArticle(_ item: HistoryItem) {
        guard let articleURL = item.url,
              let title = articleURL.wmf_title,
              let siteURL = articleURL.wmf_site,
              let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            return
        }

        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .history,
            tabConfig: .assignNewTabAndSetToCurrentFromNewTabSearch(title: title, project: wmfProject)
        )

        var vcs = navigationController.viewControllers
        if vcs.last is WMFNewArticleTabViewController {
            vcs.removeLast()
        }
        articleCoordinator.start()
        if let newVC = navigationController.viewControllers.last {
            vcs.append(newVC)
            navigationController.setViewControllers(vcs, animated: true)
        }
    }
}

fileprivate extension WMFArticle {
    func toHistoryRecord() -> HistoryRecord {
        let id = Int(truncating: self.pageID ?? NSNumber())
        let viewed = self.viewedDate ?? self.savedDate ?? Date()
        return HistoryRecord(
            id: id,
            title: self.displayTitle ?? self.displayTitleHTML,
            descriptionOrSnippet:self.capitalizedWikidataDescriptionOrSnippet,
            shortDescription: self.snippet,
            articleURL: self.url,
            imageURL: self.imageURLString,
            viewedDate: viewed,
            isSaved: self.isSaved,
            snippet: self.snippet,
            variant: self.variant
        )
    }
}
