enum UITestLaunchArgument: String {
    case appThemeName = "-WMFAppThemeName"
    case didShowOnboarding = "-DidShowOnboarding5.3"
    case uiTestLanguageCode = "-WMFUITestLanguageCode"
}

struct UITestLaunchArgumentValue {
    let key: UITestLaunchArgument
    let value: String

    init(_ key: UITestLaunchArgument, value: String) {
        self.key = key
        self.value = value
    }
}
