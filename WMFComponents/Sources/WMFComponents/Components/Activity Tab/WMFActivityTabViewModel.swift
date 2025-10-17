import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityTabViewModel: NSObject, ObservableObject {
    var localizedStrings: LocalizedStrings
    @Published var username: String
    @Published var hoursRead: Int
    @Published var minutesRead: Int
    
    public init(localizedStrings: LocalizedStrings, username: String, hoursRead: Int, minutesRead: Int) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.hoursRead = hoursRead
        self.minutesRead = minutesRead
        super.init()
    }
    
    public var usernamesReading: String {
        localizedStrings.userNamesReading(username)
    }
    
    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(hoursRead, minutesRead)
    }

    public func updateHoursMinutesRead(hours: Int, minutes: Int) {
        self.hoursRead = hours
        self.minutesRead = minutes
    }
    
    public func updateUsername(username: String) {
        self.username = username
    }

    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        var totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        
        public init(userNamesReading: @escaping (String) -> String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String) {
            self.userNamesReading = userNamesReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
        }
    }
}
