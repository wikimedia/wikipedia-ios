import UIKit
import WMF
import WMFComponents
import WMFData

final class NewArticleTabCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    private var dataStore: MWKDataStore
    private var theme: Theme
    private var dataController = WMFArticleTabsDataController.shared
    private let cameFromNewTab: Bool
    private let tabIdentifier: WMFArticleTabsDataController.Identifiers?

    // MARK: - Related pages props
    private let fetcher: RelatedSearchFetcher
    private var seed: WMFArticle?
    private var related: [WMFArticle] = []
    private var seenSeedKeys = Set<String>()
    private let contentSource = WMFRelatedPagesContentSource()

    // MARK: - Did you know props
    private var dykFetcher: WMFFeedDidYouKnowFetcher
    public var dykFacts: [WMFFeedDidYouKnow]? = nil

    private let fromWikipediaDefault = CommonStrings.fromWikipediaDefault
    private let didYouKnowTitle = WMFLocalizedString("did-you-know", value: "Did you know", comment: "Text displayed as heading for section of new tab dedicated to DYK")

    // MARK: - Lifecycle
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fetcher: RelatedSearchFetcher = RelatedSearchFetcher(), cameFromNewTab: Bool, tabIdentifier: WMFArticleTabsDataController.Identifiers? = nil) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fetcher = fetcher
        self.cameFromNewTab = cameFromNewTab
        self.tabIdentifier = tabIdentifier
        dykFetcher = WMFFeedDidYouKnowFetcher()
    }

    // MARK: - Methods
    @discardableResult
    func start() -> Bool {
        let experiment = try? self.dataController.getMoreDynamicTabsExperimentAssignment()
        let devSettingsDataController = WMFDeveloperSettingsDataController.shared
        let enableBYR = devSettingsDataController.enableMoreDynamicTabsBYR
        let enableDYK = devSettingsDataController.enableMoreDynamicTabsDYK

        if experiment == .didYouKnow || experiment == .becauseYouRead || enableBYR || enableDYK, let primaryLanguage = self.dataStore.languageLinkController.appLanguage?.languageCode {
            fetchBecauseYouReadAndDYK(language: primaryLanguage) { seedArticle, related, facts in
                var becauseVM: WMFBecauseYouReadViewModel?
                
                if let seedArticle {
                    let seedRecord = seedArticle.toHistoryRecord()
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
                
                let dykVM = WMFNewArticleTabDidYouKnowViewModel(
                    facts: facts?.map { $0.html } ?? [],
                    languageCode: primaryLanguage,
                    dykLocalizedStrings: WMFNewArticleTabDidYouKnowViewModel.LocalizedStrings.init(
                        didYouKnowTitle: self.didYouKnowTitle,
                        fromSource: self.stringWithLocalizedCurrentSiteLanguageReplacingPlaceholder(in: CommonStrings.fromWikipedia, fallingBackOn: CommonStrings.defaultFromWikipedia)
                    )
                )
                
                let viewModel = WMFNewArticleTabViewModel(
                    title: CommonStrings.newTab,
                    becauseYouReadViewModel: becauseVM,
                    dykViewModel: dykVM
                )
                
                let vc = WMFNewArticleTabViewController(
                    dataStore: self.dataStore,
                    theme: self.theme,
                    viewModel: viewModel,
                    cameFromNewTab: self.cameFromNewTab,
                    tabIdentifier: self.tabIdentifier
                )
                
                self.navigationController.pushViewController(vc, animated: true)
            }
        } else {
            let viewModel = WMFNewArticleTabViewModel(
                title: CommonStrings.newTab,
                becauseYouReadViewModel: nil,
                dykViewModel: nil
            )
            
            let vc = WMFNewArticleTabViewController(
                dataStore: self.dataStore,
                theme: self.theme,
                viewModel: viewModel,
                cameFromNewTab: self.cameFromNewTab,
                tabIdentifier: self.tabIdentifier
            )
            
            self.navigationController.pushViewController(vc, animated: true)
        }
        
        return true
    }

    // MARK: - Fetchers
    func fetchBecauseYouReadAndDYK(language: String, completion: @escaping (_ seed: WMFArticle?, _ related: [WMFArticle], _ dykFacts: [WMFFeedDidYouKnow]?) -> Void) {
        var seedArticle: WMFArticle?
        var relatedArticles: [WMFArticle] = []
        var didYouKnowFacts: [WMFFeedDidYouKnow]?
        
        let group = DispatchGroup()
        
        group.enter()
        fetchBecauseYouRead { seed, related in
            seedArticle = seed
            relatedArticles = related
            group.leave()
        }
        
        group.enter()
        fetchDYK(for: language) { facts in
            didYouKnowFacts = facts
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(seedArticle, relatedArticles, didYouKnowFacts)
        }
    }

    private func fetchBecauseYouRead(completion: @escaping (WMFArticle?, [WMFArticle]) -> Void) {
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


    private func fetchDYK(for language: String, completion: @escaping ([WMFFeedDidYouKnow]?) -> Void) {
        guard let url = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: language) else {
            completion(nil)
            return
        }
        
        dykFetcher.fetchDidYouKnow(withSiteURL: url) { error, facts in
            guard error == nil else {
                completion(nil)
                return
            }
            completion(facts)
        }
    }

    private func tappedArticle(_ item: HistoryItem) {
        guard let articleURL = item.url,
              let title = articleURL.wmf_title,
              let siteURL = articleURL.wmf_site,
              let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            return
        }

        let tabConfig: ArticleTabConfig

        if let tabIdentifier {
            tabConfig = .appendArticleToEmptyTabAndSetToCurrent(identifiers: tabIdentifier)
        } else {
            tabConfig = .assignNewTabAndSetToCurrentFromNewTabSearch(title: title, project: wmfProject)
        }

        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .history,
            tabConfig: tabConfig
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
        ArticleTabsFunnel.shared.logBecauseYouReadClick()
    }

    private func stringWithLocalizedCurrentSiteLanguageReplacingPlaceholder(in format: String, fallingBackOn genericString: String
    ) -> String {
        guard let code = self.dataStore.languageLinkController.appLanguage?.languageCode else {
            return genericString
        }

        if let language = Locale.current.localizedString(forLanguageCode: code) {
            return String.localizedStringWithFormat(format, language)
        } else {
            if code == "test" {
                return String.localizedStringWithFormat(format, "Test")
            } else if code == "test2" {
                return String.localizedStringWithFormat(format, "Test 2")
            } else {
                return genericString
            }
        }
    }
}

// MARK: - Extensions

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
