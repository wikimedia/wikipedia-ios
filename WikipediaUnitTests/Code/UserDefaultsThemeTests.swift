@testable import Wikipedia
import UIKit
import XCTest

final class UserDefaultsThemeTests: XCTestCase {
    private let defaultsSuiteName = "UserDefaultsThemeTests"

    func testDefaultThemeReturnsLightForSystemLight() {
        let defaults = makeDefaults()
        defaults.themeName = Theme.defaultThemeName
        defaults.wmf_isImageDimmingEnabled = true

        let theme = defaults.theme(compatibleWith: UITraitCollection(userInterfaceStyle: .light))

        XCTAssertEqual(theme.name, Theme.light.name)
        XCTAssertEqual(theme.imageOpacity, Theme.light.imageOpacity)
        XCTAssertFalse(theme.isDark)
    }

    func testDefaultThemeReturnsBlackForSystemDark() {
        let defaults = makeDefaults()
        defaults.themeName = Theme.defaultThemeName
        defaults.wmf_isImageDimmingEnabled = false

        let theme = defaults.theme(compatibleWith: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertEqual(theme.name, Theme.black.name)
        XCTAssertEqual(theme.imageOpacity, Theme.black.imageOpacity)
        XCTAssertTrue(theme.isDark)
    }

    func testDefaultThemeReturnsBlackDimmedForSystemDark() {
        let defaults = makeDefaults()
        defaults.themeName = Theme.defaultThemeName
        defaults.wmf_isImageDimmingEnabled = true

        let theme = defaults.theme(compatibleWith: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertEqual(theme.name, Theme.blackDimmed.name)
        XCTAssertEqual(theme.imageOpacity, Theme.blackDimmed.imageOpacity)
        XCTAssertTrue(theme.isDark)
        XCTAssertTrue(theme.isDimmed)
    }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: defaultsSuiteName)!
        // reset defaults
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        return defaults
    }
}
