import XCTest
@testable import WMFData
import WMFDataMocks

final class WMFDonorStatusDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    // MARK: - Helpers

    /// The `userinfo` response of a logged-in reader. The other options show that only the donor
    /// preference is decoded.
    private func userInfoJSON(wikimediaDonor: String?) -> String {
        let preference = wikimediaDonor.map { "\"wikimedia-donor\": \(jsonString($0)),"  } ?? ""
        return """
        {
          "batchcomplete": "",
          "query": {
            "userinfo": {
              "id": 123,
              "name": "Reader",
              "options": {
                "skin": "vector-2022",
                "centralnotice-display-campaign-type-fundraising": true,
                "rcdays": 7,
                "echo-subscriptions-web-edit-thank": null,
                \(preference)
                "language": "en"
              }
            }
          }
        }
        """
    }

    /// `text` as a JSON string literal, with its quotes escaped.
    private func jsonString(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func donorPreference(value: Int) -> String {
        "{\"source\":\"reader-donor-account\",\"value\":\(value),\"timestamp\":1760000000}"
    }

    private func fetchStatus(wikimediaDonor: String?) async throws -> WMFWebDonorStatus? {
        let service = WMFMockJSONService(json: userInfoJSON(wikimediaDonor: wikimediaDonor))
        let dataController = WMFDonorStatusDataController(mediaWikiService: service)
        return try await dataController.fetchWebDonorStatus(project: enProject)
    }

    // MARK: - Codes

    func testOnlyRecentSustainingAndReturningDonorsAreRecentDonors() {
        let expectations: [WMFDonorCode: Bool] = [.none: false, .recent: true, .sustaining: true, .lapsed: false, .returning: true, .contactable: false]
        for (code, isRecentDonor) in expectations {
            XCTAssertEqual(code.isRecentDonor, isRecentDonor, "\(code)")
        }
    }

    // MARK: - Preference parsing

    func testAnEmptyPreferenceMeansNoConsent() {
        XCTAssertNil(WMFDonorStatusDataController.webDonorStatus(fromPreference: ""))
    }

    func testTheRecentDonorCodeIsADonor() throws {
        let status = try XCTUnwrap(WMFDonorStatusDataController.webDonorStatus(fromPreference: donorPreference(value: 1)))
        XCTAssertEqual(status.code, .recent)
        XCTAssertEqual(status.source, "reader-donor-account")
        XCTAssertTrue(status.isRecentDonor)
    }

    func testTheContactableCodeIsNotADonor() throws {
        let status = try XCTUnwrap(WMFDonorStatusDataController.webDonorStatus(fromPreference: donorPreference(value: 5)))
        XCTAssertEqual(status.code, .contactable)
        XCTAssertFalse(status.isRecentDonor)
    }

    /// The CiviCRM relationship table has more codes than the preference documents. They do not count.
    func testAnUnknownCodeIsNotADonor() throws {
        let status = try XCTUnwrap(WMFDonorStatusDataController.webDonorStatus(fromPreference: donorPreference(value: 50)))
        XCTAssertNil(status.code)
        XCTAssertFalse(status.isRecentDonor)
    }

    func testACodeStoredAsTextIsAccepted() throws {
        let status = try XCTUnwrap(WMFDonorStatusDataController.webDonorStatus(fromPreference: "{\"value\":\"2\"}"))
        XCTAssertEqual(status.code, .sustaining)
    }

    func testAMalformedPreferenceIsNotADonor() throws {
        let status = try XCTUnwrap(WMFDonorStatusDataController.webDonorStatus(fromPreference: "not json"))
        XCTAssertNil(status.code)
        XCTAssertFalse(status.isRecentDonor)
    }

    // MARK: - Request

    func testFetchReadsTheDonorPreferenceFromTheUserInfoOptions() async throws {
        let status = try await fetchStatus(wikimediaDonor: donorPreference(value: 4))

        XCTAssertEqual(status?.code, .returning)
        XCTAssertTrue(status?.isRecentDonor == true)
    }

    func testFetchReturnsNoStatusWhenTheReaderDidNotConsent() async throws {
        let status = try await fetchStatus(wikimediaDonor: "")
        XCTAssertNil(status)
    }

    func testFetchTreatsAMissingPreferenceAsNoConsent() async throws {
        let status = try await fetchStatus(wikimediaDonor: nil)
        XCTAssertNil(status)
    }

    func testFetchRequestsTheUserInfoOptionsOfTheProject() async throws {
        let service = WMFMockJSONService(json: userInfoJSON(wikimediaDonor: ""))
        let dataController = WMFDonorStatusDataController(mediaWikiService: service)

        _ = try await dataController.fetchWebDonorStatus(project: enProject)

        let url = try XCTUnwrap(service.requestedURLs.first)
        XCTAssertEqual(url.host, "en.wikipedia.org")
        XCTAssertEqual(url.path, "/w/api.php")
    }

    func testFetchThrowsTheAPIErrorOfALoggedOutReader() async {
        let json = """
        {"errors": [{"code": "assertuserfailed", "html": "You must be logged in.", "module": "main"}], "docref": "See https://en.wikipedia.org/w/api.php"}
        """
        let dataController = WMFDonorStatusDataController(mediaWikiService: WMFMockJSONService(json: json))

        do {
            _ = try await dataController.fetchWebDonorStatus(project: enProject)
            XCTFail("expected an error")
        } catch WMFDataControllerError.mediaWikiResponseError(let error) {
            XCTAssertEqual(error.code, "assertuserfailed")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testFetchThrowsWithoutAService() async {
        let dataController = WMFDonorStatusDataController(mediaWikiService: nil)

        do {
            _ = try await dataController.fetchWebDonorStatus(project: enProject)
            XCTFail("expected an error")
        } catch WMFDataControllerError.mediaWikiServiceUnavailable {
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testFetchThrowsWhenTheRequestFails() async {
        let dataController = WMFDonorStatusDataController(mediaWikiService: WMFMockServiceNoInternetConnection())

        do {
            _ = try await dataController.fetchWebDonorStatus(project: enProject)
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as NSError).code, NSURLErrorNotConnectedToInternet)
        }
    }
}
