import Foundation
import CoreData

#if TEST || UITEST

/// Describes the saved articles and reading lists a UI test wants on device before launch.
/// The UI-test target sends it as base64 JSON through the `-WMFUITestReadingListsSeed` launch argument.
public struct UITestReadingListsSeed: Codable {
    public struct ReadingList: Codable {
        public let name: String
        public let description: String?
        public let createdMinutesAgo: Int
    }

    public struct Article: Codable {
        public let title: String
        public let description: String?
        public let snippet: String?
        public let savedMinutesAgo: Int
        public let readingListNames: [String]
    }

    public let readingLists: [ReadingList]
    public let articles: [Article]
}

/// Replaces the saved articles and reading lists on device with the seed from the launch arguments.
/// The seed goes through the same controllers a user action goes through, so the data is the data
/// a user would have after saving and organizing those articles. Articles are marked downloaded so
/// the fixture-backed test run does not try to download them.
public final class UITestReadingListsSeeder {
    public static let launchArgumentKey = "WMFUITestReadingListsSeed"

    private let dataStore: MWKDataStore

    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    public func applyIfNeeded(userDefaults: UserDefaults = .standard) {
        guard let base64 = userDefaults.string(forKey: Self.launchArgumentKey),
              let data = Data(base64Encoded: base64),
              let seed = try? JSONDecoder().decode(UITestReadingListsSeed.self, from: data) else {
            return
        }

        do {
            try reset()
            try apply(seed)
        } catch {
            assertionFailure("UI test reading lists seed failed: \(error)")
        }
    }

    private func reset() throws {
        let moc = dataStore.viewContext

        let listsRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        listsRequest.predicate = NSPredicate(format: "isDeletedLocally == NO && isDefault == NO")
        let lists = try moc.fetch(listsRequest)
        if !lists.isEmpty {
            try dataStore.readingListsController.delete(readingLists: lists)
        }

        let articlesRequest: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
        articlesRequest.predicate = NSPredicate(format: "savedDate != NULL")
        for article in try moc.fetch(articlesRequest) {
            guard let url = article.url else { continue }
            dataStore.savedPageList.removeEntry(with: url)
        }

        if moc.hasChanges {
            try moc.save()
        }
    }

    private func apply(_ seed: UITestReadingListsSeed) throws {
        let moc = dataStore.viewContext
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL else {
            return
        }

        // The fixture-backed remote configuration has no reading list limits, and the app stores
        // the missing values as 0. Use the production defaults so lists can be created.
        dataStore.readingListsController.maxListsPerUser = 100
        dataStore.readingListsController.maxEntriesPerList = 5000

        var listsByName: [String: ReadingList] = [:]
        for seedList in seed.readingLists {
            let list = try dataStore.readingListsController.createReadingList(named: seedList.name, description: seedList.description)
            list.createdDate = Self.date(minutesAgo: seedList.createdMinutesAgo)
            list.updatedDate = list.createdDate
            listsByName[seedList.name] = list
        }

        for seedArticle in seed.articles {
            guard let url = siteURL.wmf_URL(withTitle: seedArticle.title),
                  let article = dataStore.fetchOrCreateArticle(with: url) else {
                continue
            }
            article.displayTitleHTML = seedArticle.title
            article.wikidataDescription = seedArticle.description
            article.snippet = seedArticle.snippet
            article.isDownloaded = true

            dataStore.savedPageList.addSavedPage(with: url)

            let savedDate = Self.date(minutesAgo: seedArticle.savedMinutesAgo)
            article.savedDate = savedDate as Date
            article.isDownloaded = true

            for name in seedArticle.readingListNames {
                guard let list = listsByName[name] else { continue }
                try dataStore.readingListsController.add(articles: [article], to: list)
            }

            if let key = article.key {
                let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
                entriesRequest.predicate = NSPredicate(format: "articleKey == %@ && isDeletedLocally == NO", key)
                for entry in try moc.fetch(entriesRequest) {
                    entry.createdDate = savedDate
                    entry.updatedDate = savedDate
                }
            }
        }

        if moc.hasChanges {
            try moc.save()
        }
    }

    private static func date(minutesAgo: Int) -> NSDate {
        NSDate(timeIntervalSinceNow: -TimeInterval(minutesAgo * 60))
    }
}

#endif
