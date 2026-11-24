import Foundation
import Testing
@testable import WMFData

struct WMFHCaptchaRequirementTests {

    // Logged-out action=edit on test.wikipedia.org, 2026-11-23.
    private let testwikiEditResponse = """
    {
        "edit": {
            "captcha": {
                "type": "hcaptcha",
                "mime": "application/javascript",
                "key": "5d0c670e-a5f4-4258-ad16-1f42792c9c62",
                "error": "missing-token"
            },
            "result": "Failure"
        }
    }
    """

    // wbsetdescription on test.wikidata.org, from the Android app's test fixture.
    private let testWikidataErrorResponse = """
    {
        "errors": [
            {
                "code": "failed-save",
                "html": "The save has failed.",
                "data": {
                    "messages": [
                        { "name": "wikibase-api-failed-save", "parameters": [], "html": "The save has failed." },
                        { "name": "captcha-edit-fail", "parameters": [], "html": "Incorrect or missing CAPTCHA." }
                    ],
                    "captcha": {
                        "type": "hcaptcha",
                        "mime": "application/javascript",
                        "key": "5d0c670e-a5f4-4258-ad16-1f42792c9c62",
                        "error": "missing-token"
                    }
                },
                "module": "main"
            }
        ]
    }
    """

    private func dictionary(_ json: String) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try #require(object as? [String: Any])
    }

    @Test func parsesEditResultFromTestwiki() throws {
        let response = try dictionary(testwikiEditResponse)
        let editResult = try #require(response["edit"] as? [String: Any])

        let requirement = try #require(WMFHCaptchaRequirement(editResult: editResult))

        #expect(requirement.siteKey == "5d0c670e-a5f4-4258-ad16-1f42792c9c62")
        #expect(requirement.forceShowCaptcha == false)
    }

    @Test func parsesWikibaseErrorResponse() throws {
        let response = try dictionary(testWikidataErrorResponse)

        let requirement = try #require(WMFHCaptchaRequirement(apiErrorResponse: response))

        #expect(requirement.siteKey == "5d0c670e-a5f4-4258-ad16-1f42792c9c62")
        #expect(requirement.forceShowCaptcha == false)
    }

    @Test func parsesLegacySingleErrorFormat() throws {
        let response: [String: Any] = [
            "error": [
                "code": "failed-save",
                "data": ["captcha": ["type": "hcaptcha", "key": "abc"]]
            ]
        ]

        let requirement = try #require(WMFHCaptchaRequirement(apiErrorResponse: response))

        #expect(requirement.siteKey == "abc")
    }

    @Test func forceShowCaptchaErrorRequestsVisibleChallenge() {
        let requirement = WMFHCaptchaRequirement(captcha: ["type": "hcaptcha", "key": "abc", "error": "forceshowcaptcha"])

        #expect(requirement?.forceShowCaptcha == true)
    }

    @Test func missingOrEmptyKeyGivesNilSiteKey() {
        #expect(WMFHCaptchaRequirement(captcha: ["type": "hcaptcha"])?.siteKey == nil)
        #expect(WMFHCaptchaRequirement(captcha: ["type": "hcaptcha", "key": ""])?.siteKey == nil)
    }

    @Test func unknownErrorValueIsNotForceShow() {
        let requirement = WMFHCaptchaRequirement(captcha: ["type": "hcaptcha", "key": "abc", "error": "some-future-value"])

        #expect(requirement != nil)
        #expect(requirement?.forceShowCaptcha == false)
    }

    @Test func classicCaptchaIsNotHCaptcha() {
        let classic: [String: Any] = ["type": "image", "mime": "image/png", "id": "123", "url": "/w/index.php?title=Special:Captcha/image"]

        #expect(WMFHCaptchaRequirement(captcha: classic) == nil)
        #expect(WMFHCaptchaRequirement(editResult: ["result": "Failure", "captcha": classic]) == nil)
    }

    @Test func responsesWithoutCaptchaGiveNil() throws {
        #expect(WMFHCaptchaRequirement(editResult: ["result": "Success", "newrevid": 1]) == nil)
        #expect(WMFHCaptchaRequirement(apiErrorResponse: ["errors": [["code": "blocked", "data": ["blockinfo": [:]]]]]) == nil)
        #expect(WMFHCaptchaRequirement(apiErrorResponse: [:]) == nil)
    }

    @Test func requestParametersForPassiveToken() {
        #expect(WMFHCaptchaRequirement.requestParameters(token: "t", forceShowCaptcha: false) == ["captchaword": "t"])
    }

    @Test func requestParametersForVisibleChallenge() {
        #expect(WMFHCaptchaRequirement.requestParameters(token: "t", forceShowCaptcha: true) == ["captchaword": "t", "wgConfirmEditForceShowCaptcha": "1"])
    }
}
