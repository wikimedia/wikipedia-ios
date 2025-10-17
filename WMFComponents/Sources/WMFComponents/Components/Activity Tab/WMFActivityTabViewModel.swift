import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityTabViewModel: NSObject, ObservableObject {
    let localizedStrings: LocalizedStrings
    let username: String
    @Published var hoursRead: Int
    @Published var minutesRead: Int
    
    public init(localizedStrings: LocalizedStrings, username: String, hoursRead: Int, minutesRead: Int) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.hoursRead = hoursRead
        self.minutesRead = minutesRead
        print("USERNAME: \(username)\nHOURS: \(hoursRead)\nMINUTES: \(minutesRead)\n\n\n")
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
    
    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        
        public init(userNamesReading: @escaping (String) -> String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String) {
            self.userNamesReading = userNamesReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
        }
    }
}
