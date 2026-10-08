import XCTest

/// The profile decides "temporary account" from the centralauth_User cookie when the keychain has no credentials (T430460).
final class ProfileTemporaryAccountUITests: XCTestCase {

    func testPermanentUsernameCookieWithoutCredentialsShowsLoggedOutProfile() throws {
        launchWikipediaAppRobot(onboardingState: .completed, centralAuthUsername: "PermanentUsername")
            .explore
            .assertVisible()
            .openProfile()
            .assertShowsLoggedOutAccount()
    }

    func testTemporaryAccountCookieShowsTemporaryAccountProfile() throws {
        let temporaryUsername = "~2026-12345-6"
        launchWikipediaAppRobot(onboardingState: .completed, centralAuthUsername: temporaryUsername)
            .explore
            .assertVisible()
            .openProfile()
            .assertShowsTemporaryAccount(username: temporaryUsername)
    }
}
