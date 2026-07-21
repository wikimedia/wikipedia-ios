/// Enumerates launch argument keys owned by the UI-test harness.
enum UITestLaunchArgument: String {
    case appThemeName = "-WMFAppThemeName"
    case appleLanguages = "-AppleLanguages"
    case didShowOnboarding = "-DidShowOnboarding5.3"
    case enableHomeTab = "-WMFEnableHomeTabForTesting"
    case hideTipsForTesting = "-WMFHideTipsForTesting"
    case httpClientProfile = "-WMFTestHTTPClientProfile"
    case resetPreferredLanguages = "-WMFResetPreferredLanguages"
    case suppressActivityTabOnboarding = "-WMFSuppressActivityTabOnboardingForTesting"
    case suppressGamesAnnouncement = "-WMFSuppressGamesAnnouncementForTesting"
    case uiTestLanguageCode = "-WMFUITestLanguageCode"
}

/// Pairs a launch argument key with the string value passed to `XCUIApplication`.
struct UITestLaunchArgumentValue {
    let key: UITestLaunchArgument
    let value: String

    init(_ key: UITestLaunchArgument, value: String) {
        self.key = key
        self.value = value
    }
}
