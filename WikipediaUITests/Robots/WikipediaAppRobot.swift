import XCTest

/// Root robot returned after launching the app with a test configuration.
struct WikipediaAppRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(app: XCUIApplication, testCase: XCTestCase, configuration: UITestConfiguration) {
        self.base = UITestRobot(app: app, testCase: testCase)
        self.configuration = configuration
    }
}

// MARK: - Navigation

extension WikipediaAppRobot {
    var home: HomeRobot {
        HomeRobot(base: base, configuration: configuration)
    }

    var onboarding: OnboardingRobot {
        OnboardingRobot(base: base, configuration: configuration)
    }
}

// MARK: - Deep links

extension WikipediaAppRobot {
    @discardableResult
    func openSharedReadingListLink(pageIDs: [Int], languageCode: String, file: StaticString = #filePath, line: UInt = #line) -> CreateReadingListRobot {
        let payload: [String: Any] = ["list": [languageCode: pageIDs]]
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload),
              let url = URL(string: "wikipedia://\(languageCode).wikipedia.org/wiki/Special:ReadingLists?limport=\(payloadData.base64EncodedString())") else {
            XCTFail("Could not build the shared reading list link.", file: file, line: line)
            return CreateReadingListRobot(base: base, configuration: configuration)
        }
        base.app.open(url)
        return CreateReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}

// MARK: - App lifecycle

extension WikipediaAppRobot {
    @discardableResult
    func terminate() -> Self {
        base.app.terminate()
        return self
    }
}

// MARK: - Launching

/// Provides the test-case convenience API for launching the app and receiving the root robot.
extension XCTestCase {
    func launchWikipediaAppRobot(
        onboardingState: UITestConfiguration.OnboardingState,
        resetsPreferredLanguages: Bool = true,
        suppressesActivityTabOnboarding: Bool = true,
        suppressesGamesAnnouncement: Bool = true,
        suppressesHomeOnboarding: Bool = true,
        readingListsSeed: UITestReadingListsSeed? = nil,
        centralAuthUsername: String? = nil,
        discoverState: UITestConfiguration.DiscoverState = .off,
        homePhase: UITestConfiguration.HomePhase = .phase1,
        homeFeedState: UITestHomeFeedState? = nil,
        offlineRequests: [UITestOfflineRequest] = []
    ) -> WikipediaAppRobot {
        let app = XCUIApplication()
        let configuration = UITestConfiguration(
            onboardingState: onboardingState,
            resetsPreferredLanguages: resetsPreferredLanguages,
            suppressesActivityTabOnboarding: suppressesActivityTabOnboarding,
            suppressesGamesAnnouncement: suppressesGamesAnnouncement,
            suppressesHomeOnboarding: suppressesHomeOnboarding,
            readingListsSeed: readingListsSeed,
            centralAuthUsername: centralAuthUsername,
            discoverState: discoverState,
            homePhase: homePhase,
            homeFeedState: homeFeedState,
            offlineRequests: offlineRequests
        )
        app.configureForUITestLaunch(configuration: configuration)
        app.launch()
        return WikipediaAppRobot(app: app, testCase: self, configuration: configuration)
    }
}

// MARK: - Private helpers

/// Applies the launch argument configuration used by robot-based UI tests.
fileprivate extension XCUIApplication {
    func configureForUITestLaunch(configuration: UITestConfiguration = UITestConfiguration()) {
        addLaunchArguments(configuration.launchArguments)
        // On iOS 27 the XCTest automation support inside the app writes every accessibility attribute fetch to os_log,
        // and the test harness launches the app with OS_ACTIVITY_MODE=info, so all of it lands on the app's stderr:
        // about 1.5 million lines per CI job. When xcodebuild falls behind draining that pipe, the app's main thread
        // blocks in writev while answering the query, and element queries stall for 30 to 150 seconds.
        // Disabling os_log output for the app under test removes that back pressure.
        launchEnvironment["OS_ACTIVITY_MODE"] = "disable"
    }

    private func addLaunchArguments(_ argumentValues: [UITestLaunchArgumentValue]) {
        for argumentValue in argumentValues {
            // Key
            launchArguments.append(argumentValue.key.rawValue)
            // Value
            launchArguments.append(argumentValue.value)
        }
    }
}
