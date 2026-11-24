import XCTest
import WMFData
@testable import Wikipedia

@MainActor
final class HCaptchaEditChallengePresenterTests: XCTestCase {

    private let passive = WMFHCaptchaRequirement(siteKey: "key", forceShowCaptcha: false)
    private let visible = WMFHCaptchaRequirement(siteKey: "key", forceShowCaptcha: true)

    func testPresentsOnFirstAttempt() {
        XCTAssertTrue(HCaptchaEditChallengePresenter.shouldPresent(sentToken: nil, sentForceShowCaptcha: false, requirement: passive))
        XCTAssertTrue(HCaptchaEditChallengePresenter.shouldPresent(sentToken: nil, sentForceShowCaptcha: false, requirement: visible))
    }

    func testPresentsWhenServerEscalatesAPassiveRetry() {
        XCTAssertTrue(HCaptchaEditChallengePresenter.shouldPresent(sentToken: "token", sentForceShowCaptcha: false, requirement: visible))
    }

    func testDoesNotLoopAfterPassiveRetryIsRejectedAgain() {
        XCTAssertFalse(HCaptchaEditChallengePresenter.shouldPresent(sentToken: "token", sentForceShowCaptcha: false, requirement: passive))
    }

    func testDoesNotLoopAfterVisibleRetryIsRejected() {
        XCTAssertFalse(HCaptchaEditChallengePresenter.shouldPresent(sentToken: "token", sentForceShowCaptcha: true, requirement: visible))
    }

    func testServerSiteKeyWins() {
        XCTAssertEqual(HCaptchaEditChallengePresenter.siteKey(for: passive), "key")
    }
}
