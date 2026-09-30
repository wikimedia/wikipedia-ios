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
    var explore: ExploreRobot {
        ExploreRobot(base: base, configuration: configuration)
    }

    var onboarding: OnboardingRobot {
        OnboardingRobot(base: base, configuration: configuration)
    }

    var newOnboarding: NewOnboardingRobot {
        NewOnboardingRobot(base: base, configuration: configuration)
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
        enablesHomeTab: Bool = false
    ) -> WikipediaAppRobot {
        let app = XCUIApplication()
        let configuration = UITestConfiguration(
            onboardingState: onboardingState,
            resetsPreferredLanguages: resetsPreferredLanguages,
            suppressesActivityTabOnboarding: suppressesActivityTabOnboarding,
            suppressesGamesAnnouncement: suppressesGamesAnnouncement,
            enablesHomeTab: enablesHomeTab
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
