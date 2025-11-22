import SwiftUI
import WMF
import WMFData
import CocoaLumberjackSwift

@MainActor
class DatabasePopulationViewModel: ObservableObject {
    
    enum ViewedDateRange: String, CaseIterable, Identifiable {
        case pastYear = "Past Year"
        case pastMonth = "Past Month"
        case pastWeek = "Past Week"
        case past3Days = "Past 3 Days"

        var id: String { rawValue }

        func randomDate() -> Date {
            let now = Date()
            let calendar = Calendar.current

            let startDate: Date

            switch self {
            case .pastYear:
                startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            case .pastMonth:
                startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            case .pastWeek:
                startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            case .past3Days:
                startDate = calendar.date(byAdding: .day, value: -3, to: now)!
            }

            let interval = now.timeIntervalSince(startDate)
            let offset = TimeInterval.random(in: 0...interval)
            return startDate.addingTimeInterval(offset)
        }
    }

    
    @Published var createLists: Bool = false
    @Published var addEntries: Bool = false
    @Published var randomizeAcrossLanguages: Bool = false

    @Published var listLimitString: String
    @Published var entryLimitString: String

    @Published var isLoading = false
    
    @Published var addViewedArticles = false
    @Published var viewedArticlesCountString = "10"
    @Published var randomizeViewedAcrossLanguages = false
    @Published var viewedDateRange: ViewedDateRange = .pastYear
    
    private let dataStore = MWKDataStore.shared()
    private var legacyContext: NSManagedObjectContext {
        dataStore.viewContext
    }
    
    private let pageViewsDataController = try? WMFPageViewsDataController()

    init() {
        let moc = dataStore.viewContext
        let savedLists = moc.wmf_numberValue(forKey: "WMFCountOfListsToCreate")?.intValue ?? 10
        let savedEntries = moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.intValue ?? 100

        listLimitString = "\(savedLists)"
        entryLimitString = "\(savedEntries)"
    }

    var listLimit: Int64 { Int64(listLimitString) ?? 10 }
    var entryLimit: Int64 { Int64(entryLimitString) ?? 100 }

    @MainActor
    func doIt() async {
        isLoading = true

        let readingListsController = dataStore.readingListsController

        let shouldRunDebugSync = createLists || addEntries

        // 1. Only run debugSync if it will actually do something
        if shouldRunDebugSync {
            await withCheckedContinuation { continuation in
                readingListsController.debugSync(
                    createLists: createLists,
                    listCount: listLimit,
                    addEntries: addEntries,
                    randomizeLanguageEntries: randomizeAcrossLanguages,
                    entryCount: entryLimit
                ) {
                    continuation.resume()
                }
            }
        }

        // 2. Populate viewed articles if requested
        if addViewedArticles {
            let count = Int(viewedArticlesCountString) ?? 10
            let random = randomizeViewedAcrossLanguages

            // Await the async version
            await populateViewedArticles(count: count, randomAcrossLanguages: random)
        }

        isLoading = false
    }

    // Make populateViewedArticles async
    private func populateViewedArticles(count: Int, randomAcrossLanguages: Bool) async {
        guard let pageViewsDataController else { return }

        var currentSiteURL = URL(string: "https://en.wikipedia.org")
        let fetcher = RandomArticleFetcher()

        // Thread-safe updates
        let responseQueue = DispatchQueue(label: "summaryResponsesQueue")
        var summaryResponses: [WMFInMemoryURLKey: ArticleSummary] = [:]

        func processBatch() async throws {
            let articlesByKey = try legacyContext
                .wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)

            for (_, article) in articlesByKey {
                guard let siteURL = article.url?.wmf_site else { continue }
                let randomDate = viewedDateRange.randomDate()
                article.viewedDate = randomDate

                if let title = article.displayTitle,
                   let languageCode = siteURL.wmf_languageCode {

                    let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: siteURL.wmf_languageVariantCode))

                    _ = try await pageViewsDataController.addPageView(
                        title: title,
                        namespaceID: 0,
                        project: project,
                        previousPageViewObjectID: nil,
                        timestamp: randomDate
                    )
                }
            }

            try legacyContext.save()
            summaryResponses.removeAll(keepingCapacity: true)
        }

        for i in 1...count {
            // Randomize language if needed
            if randomAcrossLanguages,
               let randomLanguage = dataStore.languageLinkController.allLanguages.randomElement() {
                currentSiteURL = randomLanguage.siteURL
            }

            guard let siteURL = currentSiteURL else { continue }

            await withCheckedContinuation { continuation in
                fetcher.fetchRandomArticle(withSiteURL: siteURL) { (_, result, summary) in
                    if let key = result?.wmf_inMemoryKey, let summary = summary {
                        responseQueue.sync { summaryResponses[key] = summary }
                    }
                    continuation.resume()
                }
            }

            // Every 16 fetches OR at the end → wait & process
            if i % 16 == 0 || i == count {
                do {
                    try await processBatch()
                } catch {
                    NSLog("Error processing article batch: \(error)")
                }
            }
        }
    }
}
