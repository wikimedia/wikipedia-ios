import XCTest
import WMFData
@testable import Wikipedia
@testable import WMF

class RequestErrorServerBusyTests: XCTestCase {

    private func response(statusCode: Int, retryAfter: String?) -> HTTPURLResponse {
        var headers: [String: String] = [:]
        if let retryAfter {
            headers["Retry-After"] = retryAfter
        }
        return HTTPURLResponse(url: URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Foo")!, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
    }

    func testRetryAfterInSeconds() {
        XCTAssertEqual(response(statusCode: 429, retryAfter: "30").wmf_retryAfterInterval, 30)
        XCTAssertEqual(response(statusCode: 429, retryAfter: " 12 ").wmf_retryAfterInterval, 12)
        XCTAssertNil(response(statusCode: 429, retryAfter: nil).wmf_retryAfterInterval)
        XCTAssertNil(response(statusCode: 429, retryAfter: "soon").wmf_retryAfterInterval)
    }

    func testRetryAfterRejectsNonFiniteAndCapsHugeValues() {
        XCTAssertNil(response(statusCode: 429, retryAfter: "inf").wmf_retryAfterInterval)
        XCTAssertNil(response(statusCode: 429, retryAfter: "nan").wmf_retryAfterInterval)
        XCTAssertEqual(response(statusCode: 429, retryAfter: "99999999999999999999").wmf_retryAfterInterval, HTTPURLResponse.wmf_maximumRetryAfterInterval)
        XCTAssertEqual(response(statusCode: 429, retryAfter: "-5").wmf_retryAfterInterval, 0)
        let huge = WMFHTTPErrorInfo(statusCode: 429, method: "GET", url: nil, source: "test", retryAfter: response(statusCode: 429, retryAfter: "99999999999999999999").wmf_retryAfterInterval)
        XCTAssertEqual(ClientErrorFunnel.httpErrorContext(for: huge)?["retry_after"], "86400", "Converting to Int must not trap")
    }

    func testRetryAfterAsHTTPDate() throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let header = formatter.string(from: Date(timeIntervalSinceNow: 90))

        let interval = try XCTUnwrap(response(statusCode: 503, retryAfter: header).wmf_retryAfterInterval)
        XCTAssertEqual(interval, 90, accuracy: 2)

        let past = formatter.string(from: Date(timeIntervalSinceNow: -90))
        XCTAssertEqual(response(statusCode: 503, retryAfter: past).wmf_retryAfterInterval, 0)
    }

    func testFromResponseKeepsRetryAfterOnlyForBusyStatuses() {
        let busy = RequestError.from(response: response(statusCode: 429, retryAfter: "15"))
        guard case .serverBusy(let statusCode, let retryAfter) = busy else {
            return XCTFail("429 should map to serverBusy, got \(busy)")
        }
        XCTAssertEqual(statusCode, 429)
        XCTAssertEqual(retryAfter, 15)
        XCTAssertEqual((busy as NSError).code, 429)
        XCTAssertTrue(busy.isServerBusy)

        let overloaded = RequestError.from(response: response(statusCode: 503, retryAfter: nil))
        XCTAssertTrue(overloaded.isServerBusy)
        XCTAssertNil(overloaded.retryAfter)

        let notFound = RequestError.from(response: response(statusCode: 404, retryAfter: "15"))
        guard case .http(404) = notFound else {
            return XCTFail("404 should stay a plain http error, got \(notFound)")
        }
        XCTAssertFalse(notFound.isServerBusy)
    }

    func testTransientErrorsKeepTheSession() {
        XCTAssertTrue(WMFAuthenticationManager.isTransientError(RequestError.serverBusy(statusCode: 429, retryAfter: nil)))
        XCTAssertTrue(WMFAuthenticationManager.isTransientError(RequestError.http(502)))
        XCTAssertTrue(WMFAuthenticationManager.isTransientError(URLError(.notConnectedToInternet)))
        XCTAssertFalse(WMFAuthenticationManager.isTransientError(RequestError.http(403)))
        XCTAssertFalse(WMFAuthenticationManager.isTransientError(WMFAccountLoginError.wrongPassword(nil)))
    }
}
