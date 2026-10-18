import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

struct MWKImageInfoFetcherTests {
    @Test
    func galleryInfoForImageWithoutPagesCallsFailure() async throws {
        let fetcher = StubbedImageInfoFetcher(session: Session(configuration: .current), configuration: .current)
        let preferredLanguageProvider = StubbedPreferredLanguageProvider()
        fetcher.preferredLanguageDelegate = preferredLanguageProvider
        fetcher.stubbedResult = [:]
        let siteURL = try #require(URL(string: "https://test.wikipedia.org"))

        let result: Result<Any, Error> = await withCheckedContinuation { continuation in
            fetcher.fetchGalleryInfo(forImage: "File:Example.jpg", fromSiteURL: siteURL, failure: { error in
                continuation.resume(returning: .failure(error))
            }, success: { imageInfo in
                continuation.resume(returning: .success(imageInfo))
            })
        }

        guard case .failure = result else {
            Issue.record("Expected failure for a response without query.pages")
            return
        }
    }
}

private final class StubbedImageInfoFetcher: MWKImageInfoFetcher {
    var stubbedResult: [String: Any]?

    override func urlRequestFor(from url: URL) -> URLRequest? {
        return URLRequest(url: url)
    }

    override func performMediaWikiAPIGET(for urlRequest: URLRequest, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Void) -> URLSessionTask {
        completionHandler(stubbedResult, nil, nil)
        return URLSession.shared.dataTask(with: urlRequest)
    }
}

private final class StubbedPreferredLanguageProvider: NSObject, WMFPreferredLanguageInfoProvider {
    func getPreferredContentLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }

    func getPreferredLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }
}
