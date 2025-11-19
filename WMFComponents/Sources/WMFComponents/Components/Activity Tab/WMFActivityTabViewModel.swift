import Foundation
import SwiftUI
import WMFData

public final class TimelineItem: ObservableObject, Hashable {
    public let pageWithTimestamp: WMFPageWithTimestamp

    public init(pageWithTimestamp: WMFPageWithTimestamp) {
        self.pageWithTimestamp = pageWithTimestamp
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        lhs === rhs
    }
}

public final class TimelineSection: ObservableObject, Hashable {
    public let date: Date
    @Published var items: [TimelineItem] = []
    
    init(date: Date, items: [TimelineItem]) {
        self.date = date
        self.items = items
    }
    
    // Hashable conformance using object identity
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: TimelineSection, rhs: TimelineSection) -> Bool {
        lhs === rhs
    }
}

public enum ItemType {
    case standard // no icon, logged out users, etc.
    case edit
    case read
    case save
}

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    public var onTapArticle: ((TimelineItem) -> Void)?
    
    @Published var timelineSections: [TimelineSection] = []

    var hasSeenActivityTab: () -> Void
    @Published var isLoggedIn: Bool
    public var navigateToSaved: (() -> Void)?
    public var savedArticlesModuleDataDelegate: SavedArticleModuleDataDelegate?

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController,
        hasSeenActivityTab: @escaping () -> Void,
        isLoggedIn: Bool
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.isLoggedIn = isLoggedIn
    }

    // MARK: - Fetch Main Data

    @MainActor
        func initialFetch() async {
            let timeline = (try? await dataController.fetchTimeline()) ?? [:]

            var sections: [TimelineSection] = []

            for (date, value) in timeline {
                let items = value.map { pageWithTimestamp in
                    TimelineItem(pageWithTimestamp: pageWithTimestamp)
                }
                let sortedItems = items.sorted { $0.pageWithTimestamp.timestamp > $1.pageWithTimestamp.timestamp }
                sections.append(TimelineSection(date: date, items: sortedItems))
            }

            timelineSections = sections
        }
    
    @MainActor
        func refreshData() async {
            let timeline = (try? await dataController.fetchTimeline()) ?? [:]

            for (date, value) in timeline {
                let items = value.map { pageWithTimestamp in
                    TimelineItem(pageWithTimestamp: pageWithTimestamp)
                }
                let sortedItems = items.sorted { $0.pageWithTimestamp.timestamp > $1.pageWithTimestamp.timestamp }

                // Update existing section if present
                if let existingSection = timelineSections.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    existingSection.items = sortedItems
                } else {
                    // Create new section if missing
                    let newSection = TimelineSection(date: date, items: sortedItems)
                    timelineSections.append(newSection)
                }
            }

            // Remove sections that no longer exist in the latest fetch
            timelineSections.removeAll { section in
                !timeline.keys.contains { Calendar.current.isDate($0, inSameDayAs: section.date) }
            }
        }

    // MARK: - View Strings

    public func updateIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    // MARK: - Helpers
    
    func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }
    
    func formatDate(_ dateTime: Date) -> String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: dateTime)
    }
    
    func onTap(_ item: TimelineItem) {
        onTapArticle?(item)
    }
    
    @MainActor
        func deleteItem(item: TimelineItem, in section: TimelineSection) async {
            
            // Tell SwiftUI we're about to change something
            //    objectWillChange.send()
            
            withAnimation {
                section.items.removeAll { $0 === item }
                timelineSections = timelineSections // hack, maybe updates some sort of snapshot
            }
            
            do {
                try await dataController.deletePageView(for: item.pageWithTimestamp)
            } catch {
                print("Failed to delete page: \(error)")
            }
        }
    
    // MARK: - Localized Strings
    
    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let noUsernameReading: String
        let totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        let totalArticlesRead: String
        let week: String
        let articlesRead: String
        let topCategories: String
        let articlesSavedTitle: String
        let remaining: (Int) -> String
		let loggedOutTitle: String
        let loggedOutSubtitle: String
        let loggedOutPrimaryCTA: String
        let loggedOutSecondaryCTA: String
        let todayTitle: String
        let yesterdayTitle: String
        let openArticle: String
        
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, loggedOutSecondaryCTA: String, todayTitle: String, yesterdayTitle: String, openArticle: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
            self.week = week
            self.articlesRead = articlesRead
            self.topCategories = topCategories
            self.articlesSavedTitle = articlesSavedTitle
            self.remaining = remaining
            self.loggedOutTitle = loggedOutTitle
            self.loggedOutSubtitle = loggedOutSubtitle
            self.loggedOutPrimaryCTA = loggedOutPrimaryCTA
            self.loggedOutSecondaryCTA = loggedOutSecondaryCTA
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.openArticle = openArticle
        }
    }
}
