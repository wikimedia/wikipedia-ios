import XCTest

extension XCTestCase {
    
    var screenshotNameSuffix: String {
        // note: not doing theme name here, since onboarding doesn't need to support our themes, only system light/dark mode.
        let deviceName = UIDevice.current.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        return "\(deviceName)-\(deviceLanguageCode)"
    }
    
    var themeName: String {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("UITestThemeLight") { return "light" }
        if arguments.contains("UITestThemeSepia") { return "sepia" }
        if arguments.contains("UITestThemeDark") { return "dark" }
        if arguments.contains("UITestThemeBlack") { return "black" }
        return "unknown"
    }
    
    var deviceLanguageCode: String {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("UITestLanguageEN") { return "en" }
        if arguments.contains("UITestLanguageHE") { return "he" }
        if arguments.contains("UITestLanguageDE") { return "de" }
        if arguments.contains("UITestLanguageVI") { return "vi" }
        return "unknown"
    }
}
