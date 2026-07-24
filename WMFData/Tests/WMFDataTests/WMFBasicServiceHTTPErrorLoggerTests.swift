import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFBasicServiceHTTPErrorLoggerTests {

    private let fixture = WMFDataTestFixture()

    @Test
    func serverErrorGETCallsHTTPErrorLogger() async {
        await fixture.withConfiguredEnvironment(configure: {}) {
            await confirmation("httpErrorLogger is called for a GET error") { called in
                WMFDataEnvironment.current.httpErrorLogger = { statusCode, urlString in
                    #expect(statusCode == 500)
                    #expect(urlString == "http://wikipedia.org")
                    called()
                }

                let service = WMFBasicService(urlSession: WMFMockServerErrorSession())
                let request = WMFBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)
                service.perform(request: request) { (_: Result<Data, Error>) in }
            }
        }
    }

    @Test
    func serverErrorPOSTCallsHTTPErrorLogger() async {
        await fixture.withConfiguredEnvironment(configure: {}) {
            await confirmation("httpErrorLogger is called for a POST error") { called in
                WMFDataEnvironment.current.httpErrorLogger = { statusCode, urlString in
                    #expect(statusCode == 500)
                    #expect(urlString == "http://wikipedia.org")
                    called()
                }

                let service = WMFBasicService(urlSession: WMFMockServerErrorSession())
                let request = WMFBasicServiceRequest(url: URL(string: "http://wikipedia.org"), method: .POST, acceptType: .json)
                service.perform(request: request) { (_: Result<Data, Error>) in }
            }
        }
    }

    @Test
    func successDoesNotCallHTTPErrorLogger() async {
        await fixture.withConfiguredEnvironment(configure: {}) {
            await confirmation("httpErrorLogger is not called on success", expectedCount: 0) { called in
                WMFDataEnvironment.current.httpErrorLogger = { _, _ in
                    called()
                }

                let service = WMFBasicService(urlSession: WMFMockSuccessURLSession())
                let request = WMFBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)
                service.perform(request: request) { (_: Result<Data, Error>) in }
            }
        }
    }
}
