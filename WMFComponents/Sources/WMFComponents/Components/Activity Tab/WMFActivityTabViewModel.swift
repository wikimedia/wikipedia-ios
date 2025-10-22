import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityTabViewModel: NSObject, ObservableObject {
    var localizedStrings: LocalizedStrings
    @Published var username: String
    @Published var hoursRead: Int
    @Published var minutesRead: Int
    @Published var totalArticlesRead: Int = 0
    @Published var dateTimeLastRead: String? = nil
    @Published var topCategories: [String]? = nil
    var hasSeenActivityTab: () -> Void
    
    public init(localizedStrings: LocalizedStrings, username: String, hoursRead: Int, minutesRead: Int, hasSeenActivityTab: @escaping () -> Void) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.hoursRead = hoursRead
        self.minutesRead = minutesRead
        self.hasSeenActivityTab = hasSeenActivityTab
        super.init()
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
    
    public func updateHoursMinutesRead(hours: Int, minutes: Int) {
        self.hoursRead = hours
        self.minutesRead = minutes
    }
    
    public func updateUsername(username: String) {
        self.username = username
    }
    
    public func updateTotalArticlesRead(totalArticlesRead: Int) {
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
    
    public func updateTopCategories(topCategories: [String]) {
        self.topCategories = topCategories
    }
    
    // Localized strings

    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let noUsernameReading: String
        var totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        let totalArticlesRead: String
        let topCategories: String

        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, topCategories: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
            self.topCategories = topCategories
        }
    }
}
