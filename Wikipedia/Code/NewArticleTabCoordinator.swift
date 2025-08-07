import UIKit
import WMF
import WMFComponents
import WMFData
import Foundation

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    private let fetcher: RelatedSearchFetcher
    var dykFetcher: WMFFeedDidYouKnowFetcher
    private let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.dykCache)
    public var dykFacts: [WMFFeedDidYouKnow]? = nil
    private var dataController = WMFArticleTabsDataController.shared
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fetcher: RelatedSearchFetcher = RelatedSearchFetcher()) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fetcher = fetcher
		dykFetcher = WMFFeedDidYouKnowFetcher()
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
            let experiment = try? self.dataController.getMoreDynamicTabsExperimentAssignment()
            let devSettingsDataController = WMFDeveloperSettingsDataController.shared
            let enableBYR = devSettingsDataController.enableMoreDynamicTabsBYR
            let enableDYK = devSettingsDataController.enableMoreDynamicTabsDYK

            if enableDYK || experiment == .didYouKnow {
                self.fetchDYK { facts in
                    DispatchQueue.main.async {
                        let dykVM = WMFNewArticleTabDidYouKnowViewModel(
                            facts: facts?.map { $0.html } ?? [],
                            languageCode: self.dataStore.languageLinkController.appLanguage?.languageCode,
                            dykLocalizedStrings: WMFNewArticleTabDidYouKnowViewModel.LocalizedStrings.init(
                                dyk: self.dyk,
                                fromSource: self.fromLanguageWikipediaTextFor(languageCode: self.dataStore.languageLinkController.appLanguage?.languageCode)
                            )
                        )

                        let viewModel = WMFNewArticleTabViewModel(
                            title: CommonStrings.newTab,
                            becauseYouReadViewModel: nil,
                            dykViewModel: dykVM
                        )

                        let vc = WMFNewArticleTabViewController(
                            dataStore: self.dataStore,
                            theme: self.theme,
                            viewModel: viewModel
                        )

                        self.navigationController.pushViewController(vc, animated: true)
                    }
                }

            } else if enableBYR || experiment == .becauseYouRead {
                var becauseVM: WMFBecauseYouReadViewModel?

                if let seed {
                    let seedRecord = seed.toHistoryRecord()
                    let relatedRecords = related.compactMap { $0.toHistoryRecord() }

                    if !relatedRecords.isEmpty {
                        let onTapArticleAction: WMFBecauseYouReadViewModel.OnRecordTapAction = { [weak self] historyItem in
                            self?.tappedArticle(historyItem)
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
                    becauseYouReadViewModel: becauseVM,
                    dykViewModel: nil
                )

                let vc = WMFNewArticleTabViewController(
                    dataStore: self.dataStore,
                    theme: self.theme,
                    viewModel: viewModel
                )

                self.navigationController.pushViewController(vc, animated: true)
            } else {
                let viewModel = WMFNewArticleTabViewModel(
                    title: CommonStrings.newTab,
                    becauseYouReadViewModel: nil,
                    dykViewModel: nil
                )

                let vc = WMFNewArticleTabViewController(
                    dataStore: self.dataStore,
                    theme: self.theme,
                    viewModel: viewModel
                )

                self.navigationController.pushViewController(vc, animated: true)
            }
        }

        return true
    }
    
    // MARK: - DYK
    
    let fromLanguageWikipedia = WMFLocalizedString("new-article-tab-from-language-wikipedia", value: "from %1$@ Wikipedia", comment: "Text displayed to indicate Did You Know source displayed on a new tab. %1$@ will be replaced with the Wikipedia language set as the app default")
    let fromWikipediaDefault = CommonStrings.fromWikipediaDefault
    let dyk = WMFLocalizedString("did-you-know", value: "Did you know", comment: "Text displayed as heading for section of new tab dedicated to DYK")
    
    private func fromLanguageWikipediaTextFor(languageCode: String?) -> String {
        guard let languageCode = languageCode, let localizedLanguageString = Locale.current.localizedString(forLanguageCode: languageCode) else {
            return fromWikipediaDefault
        }

        return String.localizedStringWithFormat(fromLanguageWikipedia, localizedLanguageString)
    }
    
    private func fetchDYK(completion: @escaping ([WMFFeedDidYouKnow]?) -> Void) {
        guard let url = URL(string: Configuration.current.defaultSiteDomain) else {
            completion(nil)
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stringToday = today.formatted()
        let key = "dyk-last-fetch-date"
        
        let lastChecked = try? userDefaultsStore?.load(key: key) ?? ""
        
        let wasCheckedToday = stringToday == lastChecked

        let cached = sharedCache.loadCache() ?? DidYouKnowCache()
        let facts = cached.facts

        if wasCheckedToday, let facts = facts, !facts.isEmpty {
            completion(facts)
            return
        }

        try? sharedCache.removeCache()

        dykFetcher.fetchDidYouKnow(withSiteURL: url) { [weak self] error, facts in
            guard error == nil else {
                completion(nil)
                return
            }
            self?.dykFacts = facts
            self?.sharedCache.saveCache(facts)
            try? self?.userDefaultsStore?.save(key: key, value: stringToday)
            completion(facts)
        }
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
