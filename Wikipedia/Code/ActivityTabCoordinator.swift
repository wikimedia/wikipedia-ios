import UIKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFActivityTabCoordinator)
public final class ActivityTabCoordinator: NSObject, Coordinator {
    var theme: Theme
    let dataStore: MWKDataStore
    var navigationController: UINavigationController
    private weak var viewModel: WMFActivityTabViewModel?
    let dataController: WMFActivityTabDataController
    
    public init(theme: Theme, dataStore: MWKDataStore, navigationController: UINavigationController, viewModel: WMFActivityTabViewModel? = nil, dataController: WMFActivityTabDataController) {
        self.theme = theme
        self.dataStore = dataStore
        self.navigationController = navigationController
        self.viewModel = viewModel
        self.dataController = dataController
    }
    
    @discardableResult
    func start() -> Bool {
        guard let username = dataStore.authenticationManager.authStatePermanentUsername else {
            return false
        }
        
        var hoursRead: Int = 0
        var minutesRead: Int = 0
        Task {
            if let (hours, minutes) = try? await dataController.getTimeReadPast7Days() {
                hoursRead = hours
                minutesRead = minutes
            }
        }
        
        let viewModel = WMFActivityTabViewModel(localizedStrings: WMFActivityTabViewModel.LocalizedStrings(
            userNamesReading: usernamesReading(username: username),
            totalHoursMinutesRead: hoursMinutesRead(hours: hoursRead, minutes: minutesRead),
            onWikipediaiOS: onWikipediaiOS))
        
        let activityTab = WMFActivityTabView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: activityTab)
        navigationController.present(hostingController, animated: true, completion: nil)
        return true
    }
    
    // MARK: - Localized strings
    
    func usernamesReading(username: String) -> String {
        let format = WMFLocalizedString("activity-tab-usernames-reading-title", value: "%1$@'s reading", comment: "Activity tab header, includes username and their reading, like User's reading where $1 is replaced with the username.")
        return String.localizedStringWithFormat(format, username)
    }
    
    func hoursMinutesRead(hours: Int, minutes: Int) -> String {
        let format = WMFLocalizedString("activity-tab-hours-minutes-read", value: "%1$@h %2$@m", comment: "Activity tab header, $1 is the amount of hours they spent reading, h is for the first letter of Hours, $2 is the amount of minutes they spent reading, m is for the first letter of Minutes.")
        return String.localizedStringWithFormat(format, hours, minutes)
    }
    
    let onWikipediaiOS = WMFLocalizedString("activity-tab-hours-on-wikipedia-ios", value: "ON WIKIPEDIA iOS", comment: "Activity tab header for on Wikipedia iOS, entirely capitalized except for iOS, which maintains its proper capitalization")
}
