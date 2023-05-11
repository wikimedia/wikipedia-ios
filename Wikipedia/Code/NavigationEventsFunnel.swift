import Foundation

final internal class NavigationEventsFunnel {
    internal static let shared = NavigationEventsFunnel()

    internal enum NavigationAction: String, Codable {
        case explore
        case places
        case saved
        case saved_all
        case saved_lists
        case history
        case search
        case setting_open_nav
        case setting_open_explore
        case setting_account
        case setting_close
        case setting_fundraise
        case setting_languages
        case setting_search
        case setting_explorefeed
        case setting_notifications
        case setting_read_prefs
        case setting_storagesync
        case setting_read_danger
        case setting_cleardata
        case setting_privacy
        case setting_tos
        case setting_usage_reports
        case setting_rate
        case setting_help
        case setting_about
        case article_toolbar_toc
        case article_toolbar_lang
        case article_toolbar_lang_success
        case article_toolbar_save
        case article_toolbar_save_success
        case article_toolbar_share
        case article_toolbar_share_success
        case article_toolbar_appearance
        case article_toolbar_search
        case article_toolbar_search_success
    }

    private struct Event: EventInterface {
        static var schema: EventPlatformClient.Schema = .navigation
        let action: NavigationAction
    }

    func logEvent(action: NavigationAction) {
        let event = Event(action: action)
        EventPlatformClient.shared.submit(stream: .navigation, event: event)
    }

}
