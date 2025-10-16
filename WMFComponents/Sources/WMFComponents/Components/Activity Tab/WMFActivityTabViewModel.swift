import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityTabViewModel: NSObject, ObservableObject {
    let localizedStrings: LocalizedStrings

    public init(localizedStrings: LocalizedStrings) {
        self.localizedStrings = localizedStrings
    }
    
    public struct LocalizedStrings {
        let userNamesReading: String
        let totalHoursMinutesRead: String
        let onWikipediaiOS: String
        
        public init(userNamesReading: String, totalHoursMinutesRead: String, onWikipediaiOS: String) {
            self.userNamesReading = userNamesReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
        }
    }
}
