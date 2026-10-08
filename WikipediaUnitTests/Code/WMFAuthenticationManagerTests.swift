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
}
