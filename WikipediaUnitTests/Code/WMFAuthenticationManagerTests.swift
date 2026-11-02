import XCTest
@testable import WMF

final class WMFAuthenticationManagerTests: XCTestCase {

    func testTemporaryAccountUsernameStartsWithTilde() {
        XCTAssertTrue(WMFAuthenticationManager.isTemporaryAccountUsername("~2026-12345-6"))
    }

    func testPermanentUsernameIsNotTemporary() {
        // A permanent username left in the centralauth_User cookie by an unfinished logout (T430460)
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername("Reedy"))
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername("User~WithTildeInside"))
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername(""))
    }

    func testLoggedOutAlertShowsAfterLogoutWhileLoggedOut() {
        XCTAssertTrue(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: true, isPermanentAccountLoggedIn: false))
    }

    func testLoggedOutAlertIsSkippedOnceLoggedInAgain() {
        // The alert was dismissed by a link, then the user logged in from Settings.
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: true, isPermanentAccountLoggedIn: true))
    }

    func testLoggedOutAlertNeedsAnUnacknowledgedLogout() {
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: false, isPermanentAccountLoggedIn: false))
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: false, isPermanentAccountLoggedIn: true))
    }
}
