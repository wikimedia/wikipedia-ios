import Foundation
import WMFData
import WMF
import WMFComponents

protocol NewArticleTabDataControlling {
    func loadBecauseYouRead() async throws -> WMFBecauseYouReadViewModel?
    func loadDidYouKnow() async throws -> WMFNewArticleTabDidYouKnowViewModel?
}

final class NewArticleTabDataController: NewArticleTabDataControlling {
    private let dataStore: MWKDataStore
    private let relatedFetcher = RelatedSearchFetcher()
    private let dykFetcher = WMFFeedDidYouKnowFetcher()

    private var seenSeedKeys = Set<String>()
    private var seed: WMFArticle?
    private var related: [WMFArticle] = []

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    // MARK: - BYR

    func loadBecauseYouRead() async throws -> WMFBecauseYouReadViewModel? {
        guard let seed = try await mostRecentHistoryRecordWithURL() else {
            return nil
        }

        let relatedRecords = try await relatedArticles(for: seed.articleURL)

        guard !relatedRecords.isEmpty else { return nil }

        let vm = WMFBecauseYouReadViewModel(
            becauseYouReadTitle: CommonStrings.relatedPagesTitle,
            openButtonTitle: CommonStrings.articleTabsOpen,
            seedArticle: seed,
            relatedArticles: relatedRecords
        )

        return vm
    }

    // MARK: - DYK

    func loadDidYouKnow() async throws -> WMFNewArticleTabDidYouKnowViewModel? {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL
        else { return nil }

        let facts = try await didYouKnowFacts(siteURL: siteURL)
        guard let facts, !facts.isEmpty else { return nil }

        let localized = WMFNewArticleTabDidYouKnowViewModel.LocalizedStrings(
            didYouKnowTitle: WMFLocalizedString("did-you-know", value: "Did you know", comment: "Text displayed as heading for section of new tab dedicated to DYK"),
            fromSource: self.stringWithLocalizedCurrentSiteLanguageReplacingPlaceholder(in: CommonStrings.fromWikipedia, fallingBackOn: CommonStrings.defaultFromWikipedia)
        )

        let vm = WMFNewArticleTabDidYouKnowViewModel(
            facts: facts.map { $0.html },
            languageCode: dataStore.languageLinkController.appLanguage?.languageCode,
            dykLocalizedStrings: localized
        )
        return vm
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

    // MARK: - Async helpers

    @MainActor
    private func obtainFeedImportContext() -> NSManagedObjectContext {
        dataStore.feedImportContext
    }

    private func relatedArticles(for url: URL?) async throws -> [HistoryRecord] {
        try await withCheckedThrowingContinuation { cont in
            relatedFetcher.fetchRelatedArticles(forArticleWithURL: url) { error, summariesByKey in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let summariesByKey, !summariesByKey.isEmpty else {
                    cont.resume(returning: [])
                    return
                }

                // take the first 3
                let top3Summaries = Array(summariesByKey)
                    .prefix(3)
                    .reduce(into: [WMFInMemoryURLKey: ArticleSummary]()) { result, pair in
                        result[pair.key] = pair.value
                    }

                Task {
                    let moc = await self.obtainFeedImportContext()
                    await moc.perform {
                        do {
                            let articlesByKey = try moc.wmf_createOrUpdateArticleSummmaries(
                                withSummaryResponses: top3Summaries
                            )
                            let orderedKeys = Array(top3Summaries.keys)
                            let relatedArticles: [WMFArticle] = orderedKeys.compactMap {
                                articlesByKey[$0]
                            }
                            let records = relatedArticles.map { $0.toHistoryRecord() }
                            cont.resume(returning: records)
                        } catch {
                            cont.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    private func didYouKnowFacts(siteURL: URL) async throws -> [WMFFeedDidYouKnow]? {
        try await withCheckedThrowingContinuation { cont in
            dykFetcher.fetchDidYouKnow(withSiteURL: siteURL) { error, facts in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: facts) }
            }
        }
    }

    private func mostRecentHistoryRecordWithURL() async throws -> HistoryRecord? {

        let moc = await self.obtainFeedImportContext()
        var pickedSeed: WMFArticle?
        return await moc.perform {
            let req: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()

            let mainTitle = "Main Page"
            let mainKey   = "Main_Page"
            let excludeMain = NSPredicate(format: "NOT (displayTitle ==[cd] %@ OR key == %@)", mainTitle, mainKey)

            let base = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format:"isExcludedFromFeed == NO AND (wasSignificantlyViewed == YES OR savedDate != nil)"),
                        excludeMain
                    ])
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
                if let key = seed.key {
                    self.seenSeedKeys.insert(key)
                }
            }
            self.seed = pickedSeed

            return self.seed?.toHistoryRecord()
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
