import XCTest
@testable import Wikipedia
@testable import WMF

final class TalkPageFetcherTests: XCTestCase {

    /// `evaluateResponse` is pure, so no network is needed.
    private func evaluate(_ result: [String: Any]?) -> Result<Void, Error> {
        let session = Session(configuration: .current)
        let fetcher = TalkPageFetcher(session: session, configuration: .current)
        var captured: Result<Void, Error>!
        fetcher.evaluateResponse(nil, result) { captured = $0 }
        return captured
    }

    func testSuccessWithNewRevIDSucceeds() {
        let result = evaluate(["discussiontoolsedit": ["result": "success", "newrevid": 12345]])
        guard case .success = result else {
            return XCTFail("Expected success, got \(result)")
        }
    }

    func testSuccessWithoutNewRevIDIsNotSuccess() {
        let result = evaluate(["discussiontoolsedit": ["result": "success"]])
        guard case .failure = result else {
            return XCTFail("Expected failure when newrevid is missing")
        }
    }

    func testHCaptchaChallengeReturnsHCaptchaRequiredWithSiteKey() {
        // Response shape from T427887.
        let result = evaluate([
            "discussiontoolsedit": [
                "result": "error",
                "edit": [
                    "result": "Failure",
                    "captcha": [
                        "type": "hcaptcha",
                        "mime": "application/javascript",
                        "key": "5d0c670e-a5f4-4258-ad16-1f42792c9c62",
                        "error": "missing-token"
                    ]
                ]
            ]
        ])
        guard case .failure(let error) = result,
              case TalkPageDataController.TalkPageError.hCaptchaRequired(let siteKey, let forceShowCaptcha) = error else {
            return XCTFail("Expected hCaptchaRequired, got \(result)")
        }
        XCTAssertEqual(siteKey, "5d0c670e-a5f4-4258-ad16-1f42792c9c62")
        XCTAssertFalse(forceShowCaptcha)
    }

    func testForceShowCaptchaChallengeSetsForceShowFlag() {
        // AbuseFilter "showcaptcha": always-challenge sitekey + error=forceshowcaptcha.
        let result = evaluate([
            "discussiontoolsedit": [
                "result": "error",
                "edit": [
                    "result": "Failure",
                    "captcha": [
                        "type": "hcaptcha",
                        "key": "always-challenge-key",
                        "error": "forceshowcaptcha"
                    ]
                ]
            ]
        ])
        guard case .failure(let error) = result,
              case TalkPageDataController.TalkPageError.hCaptchaRequired(let siteKey, let forceShowCaptcha) = error else {
            return XCTFail("Expected hCaptchaRequired, got \(result)")
        }
        XCTAssertEqual(siteKey, "always-challenge-key")
        XCTAssertTrue(forceShowCaptcha)
    }

    func testTopLevelAPIErrorReturnsAPIError() {
        let result = evaluate(["error": ["info": "Some API error", "code": "badtoken"]])
        guard case .failure(let error) = result, case RequestError.api = error else {
            return XCTFail("Expected RequestError.api, got \(result)")
        }
    }

    func testNonCaptchaFailureReturnsUnexpectedResponse() {
        let result = evaluate(["discussiontoolsedit": ["result": "error", "edit": ["result": "Failure"]]])
        guard case .failure(let error) = result, case RequestError.unexpectedResponse = error else {
            return XCTFail("Expected unexpectedResponse, got \(result)")
        }
    }
}
