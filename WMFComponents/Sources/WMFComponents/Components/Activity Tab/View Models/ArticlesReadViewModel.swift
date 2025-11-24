import WMFData
import SwiftUI

@MainActor
public final class ArticlesReadViewModel: ObservableObject {
    @Published public var username: String = ""
    @Published public var hoursRead: Int = 0
    @Published public var minutesRead: Int = 0
    @Published public var totalArticlesRead: Int = 0
    @Published public var dateTimeLastRead: String = ""
    @Published public var weeklyReads: [Int] = []
    @Published public var topCategories: [String] = []
    @Published public var usernamesReading: String = ""

    private let dataController: WMFActivityTabDataController
    private let dateFormatter: (Date) -> String
    private let makeUsernamesReading: (String) -> String
    private let noUsernameReading: String

    public init(
        dataController: WMFActivityTabDataController = .shared,
        dateFormatter: @escaping (Date) -> String,
        makeUsernamesReading: @escaping (String) -> String,
        noUsernameReading: String
    ) {
        self.dataController = dataController
        self.dateFormatter = dateFormatter
        self.makeUsernamesReading = makeUsernamesReading
        self.noUsernameReading = noUsernameReading
    }

    public func updateUsername(_ username: String) {
        self.username = username
        self.usernamesReading = username.isEmpty ? noUsernameReading : makeUsernamesReading(username)
    }

    public func fetch() async {
            async let t = dataController.getTimeReadPast7Days()
            async let total = dataController.getArticlesRead()
            async let last = dataController.getMostRecentReadDateTime()
            async let weekly = dataController.getWeeklyReadsThisMonth()
            async let cats = dataController.getTopCategories()

            let (h, m) = (try? await t) ?? (0, 0)
            let totalRead = (try? await total) ?? 0
            let lastDate = (try? await last) ?? Date()
            let weeklyReads = (try? await weekly) ?? []
            let categories = (try? await cats) ?? []

            self.hoursRead = h
            self.minutesRead = m
            self.totalArticlesRead = totalRead
            self.dateTimeLastRead = self.dateFormatter(lastDate)
            self.weeklyReads = weeklyReads
            self.topCategories = categories
    }
}
