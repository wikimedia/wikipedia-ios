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
    
    public init(localizedStrings: LocalizedStrings, username: String, dataController: WMFActivityTabDataController) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.dataController = dataController
    }
    
    func fetchData() {
        Task {
            if let (hours, minutes) = try? await dataController.getTimeReadPast7Days() {
                updateHoursMinutesRead(hours: hours, minutes: minutes)
            }
        }
    }
    
    var usernamesReading: String {
        if username.isEmpty {
            return localizedStrings.noUsernameReading
        }
        return localizedStrings.userNamesReading(username)
    }
    
    var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(hoursRead, minutesRead)
    }

    func updateHoursMinutesRead(hours: Int, minutes: Int) {
        self.hoursRead = hours
        self.minutesRead = minutes
    }
    
    public func updateUsername(username: String) {
        self.username = username
    }

    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let noUsernameReading: String
        var totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
        }
    }
}
