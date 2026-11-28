import XCTest
import WMFComponents

/// Represents a screen that a Home feed card pushes: the full Top read list, the On this day events,
/// an In the news story, or the feed settings.
struct FeedDetailRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    enum Screen {
        case topReadList
        case onThisDay
        case news
        case communityFeedSettings
        case homeFeedSettings

        var accessibilityIdentifier: String {
            switch self {
            case .topReadList:
                return AccessibilityIdentifiers.FeedDetail.topReadListView
            case .onThisDay:
                return AccessibilityIdentifiers.FeedDetail.onThisDayView
            case .news:
                return AccessibilityIdentifiers.FeedDetail.newsView
            case .communityFeedSettings:
                return AccessibilityIdentifiers.FeedDetail.communityFeedSettingsView
            case .homeFeedSettings:
                // The root screen of the Home feed settings has no view identifier. Its first row does.
                return AccessibilityIdentifiers.HomeFeedSettings.whatsDrivingRow
            }
        }
    }
}

// MARK: - Screen state

extension FeedDetailRobot {
    @discardableResult
    func assertVisible(_ screen: Screen, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.descendants(matching: .any).matching(identifier: screen.accessibilityIdentifier).firstMatch,
            timeout: 30,
            description: "\(screen) screen",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Navigation

extension FeedDetailRobot {
    @discardableResult
    func goBackToHome(file: StaticString = #filePath, line: UInt = #line) -> HomeRobot {
        let navigationBar = base.app.navigationBars.firstMatch
        let backButton = base.backButton(in: navigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertVisible(backButton, timeout: 10, description: "back button", file: file, line: line)
        backButton.tap()
        return HomeRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}
