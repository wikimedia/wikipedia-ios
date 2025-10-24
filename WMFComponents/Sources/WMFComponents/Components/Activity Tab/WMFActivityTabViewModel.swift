import Foundation
import SwiftUI
import WMFData

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    @Published var username: String
    @Published var hoursRead: Int = 0
    @Published var minutesRead: Int = 0
    @Published var totalArticlesRead: Int = 0
    @Published var dateTimeLastRead: String? = nil
    var hasSeenActivityTab: () -> Void
    
    public init(localizedStrings: LocalizedStrings, username: String, dataController: WMFActivityTabDataController, hasSeenActivityTab: @escaping () -> Void) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
    }
    
    @MainActor
    public func viewDidLoad() {
        Task {
            if let (hours, minutes) = try? await dataController.getTimeReadPast7Days() {
                updateHoursMinutesRead(hours: hours, minutes: minutes)
            }
        }
        
        Task {
            if let articlesRead = try? await dataController.getArticlesRead() {
                updateTotalArticlesRead(totalArticlesRead: articlesRead)
            }
        }
        
        Task {
            if let dateTime = try? await dataController.getMostRecentReadDateTime() {
                updateDateTimeRead(dateTime: dateTime)
            }
        }
        
    }
    
    public var usernamesReading: String {
        if username.isEmpty {
            return localizedStrings.noUsernameReading
        }
        return localizedStrings.userNamesReading(username)
    }
    
    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(hoursRead, minutesRead)
    }

    // External updates for async
    
    private func updateHoursMinutesRead(hours: Int, minutes: Int) {
        self.hoursRead = hours
        self.minutesRead = minutes
    }
    
    public func updateUsername(username: String) {
        self.username = username
    }
    
    private func updateTotalArticlesRead(totalArticlesRead: Int) {
        self.totalArticlesRead = totalArticlesRead
    }
    
    public func updateDateTimeRead(dateTime: Date) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(dateTime) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else {
            dateFormatter.dateFormat = "MMMM d"
        }
        
        let formattedString = dateFormatter.string(from: dateTime)
        dateTimeLastRead = formattedString
    }

    
    // Localized strings

    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let noUsernameReading: String
        var totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        let totalArticlesRead: String
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
        }
    }
}
