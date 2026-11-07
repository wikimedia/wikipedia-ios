import XCTest

/// The profile decides "temporary account" from the centralauth_User cookie when the keychain has no credentials (T430460).
final class ProfileTemporaryAccountUITests: XCTestCase {

    func testPermanentUsernameCookieWithoutCredentialsShowsLoggedOutProfile() throws {
        launchWikipediaAppRobot(onboardingState: .completed, centralAuthUsername: "PermanentUsername")
            .home
            .assertVisible()
            .openProfile()
            .assertShowsLoggedOutAccount()
    }

    func testTemporaryAccountCookieShowsTemporaryAccountProfile() throws {
        try skipInE2E("The seeded temporary username only exists for fixture responses, not on live wikis.")
        let temporaryUsername = "~2026-12345-6"
        launchWikipediaAppRobot(onboardingState: .completed, centralAuthUsername: temporaryUsername)
            .home
            .assertVisible()
            .openProfile()
            .assertShowsTemporaryAccount(username: temporaryUsername)
    }
}
