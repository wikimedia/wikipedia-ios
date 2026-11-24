import XCTest
@testable import WMF
import WMFData
import WMFNativeLocalizations
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

final class HCaptchaDescriptionEditTests: XCTestCase {

    // test.wikidata.org response, from the Android app's wbsetdescription fixture.
    private let wikidataCaptchaResponse = """
    {"errors":[{"code":"failed-save","html":"The save has failed.","data":{"captcha":{"type":"hcaptcha","mime":"application/javascript","key":"5d0c670e-a5f4-4258-ad16-1f42792c9c62","error":"missing-token"}},"module":"wbsetdescription"}],"docref":"See https://test.wikidata.org/w/api.php for API usage."}
    """

    func testWikidataPublishResultReadsCaptchaFromErrorData() throws {
        let result = try JSONDecoder().decode(WikidataFetcher.WikidataAPIPublishResult.self, from: Data(wikidataCaptchaResponse.utf8))
        XCTAssertEqual(result.hCaptchaRequirement, WMFHCaptchaRequirement(siteKey: "5d0c670e-a5f4-4258-ad16-1f42792c9c62", forceShowCaptcha: false))
        XCTAssertEqual(result.errors?.first?.code, "failed-save")
    }

    func testWikidataPublishResultWithoutCaptcha() throws {
        let success = #"{"entity":{"lastrevid":123},"success":1}"#
        let result = try JSONDecoder().decode(WikidataFetcher.WikidataAPIPublishResult.self, from: Data(success.utf8))
        XCTAssertNil(result.hCaptchaRequirement)
        XCTAssertEqual(result.entity?.lastrevid, 123)

        let blocked = #"{"errors":[{"code":"blocked","html":"You are blocked.","data":{"blockinfo":null}}]}"#
        let blockedResult = try JSONDecoder().decode(WikidataFetcher.WikidataAPIPublishResult.self, from: Data(blocked.utf8))
        XCTAssertNil(blockedResult.hCaptchaRequirement)
        XCTAssertEqual(blockedResult.errors?.first?.code, "blocked")
    }

    @MainActor
    func testRequirementFromWikidataError() {
        let requirement = WMFHCaptchaRequirement(siteKey: "key", forceShowCaptcha: true)
        XCTAssertEqual(DescriptionEditViewController.hCaptchaRequirement(from: WikidataFetcher.WikidataPublishingError.needsHCaptcha(requirement)), requirement)
    }

    @MainActor
    func testRequirementFromSectionUploaderError() {
        let error = NSError(domain: "Upload Wikitext Op", code: WikiTextSectionUploaderErrorType.needsHCaptcha.rawValue, userInfo: [
            WikiTextSectionUploaderErrorUserInfoCaptchaKey: ["type": "hcaptcha", "key": "key", "error": "forceshowcaptcha"]
        ])
        XCTAssertEqual(DescriptionEditViewController.hCaptchaRequirement(from: error), WMFHCaptchaRequirement(siteKey: "key", forceShowCaptcha: true))
    }

    func testWikidataHCaptchaErrorShowsCaptchaMessage() {
        let error = WikidataFetcher.WikidataPublishingError.needsHCaptcha(WMFHCaptchaRequirement(siteKey: nil, forceShowCaptcha: false))
        XCTAssertEqual(error.errorDescription, CommonStrings.captchaVerificationError)
    }

    @MainActor
    func testNoRequirementFromOtherErrors() {
        XCTAssertNil(DescriptionEditViewController.hCaptchaRequirement(from: WikidataFetcher.WikidataPublishingError.unknown))
        let classicCaptcha = NSError(domain: "Upload Wikitext Op", code: WikiTextSectionUploaderErrorType.needsCaptcha.rawValue, userInfo: nil)
        XCTAssertNil(DescriptionEditViewController.hCaptchaRequirement(from: classicCaptcha))
    }
}
