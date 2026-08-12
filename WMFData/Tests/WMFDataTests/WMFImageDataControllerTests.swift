import Foundation
import Testing
@testable import WMFData

struct WMFImageDataControllerTests {

    private static let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private static let imageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Example.jpg/320px-Example.jpg")!
    private static let otherImageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Other.jpg/320px-Other.jpg")!
    private static let imageBytes = Data("the-image-bytes".utf8)

    // MARK: - fetchImageData

    @Test
    func fetchImageDataReturnsDataOnSuccess() async throws {
        let service = MockImageService()
        service.dataResult = .success(Self.imageBytes)
        let controller = WMFImageDataController(basicService: service, mediaWikiService: nil)

        let data = try await controller.fetchImageData(url: Self.imageURL)

        #expect(data == Self.imageBytes)
        #expect(service.dataCallCount == 1)
    }

    @Test
    func fetchImageDataServesRepeatRequestFromCacheWithoutHittingService() async throws {
        let service = MockImageService()
        service.dataResult = .success(Self.imageBytes)
        let controller = WMFImageDataController(basicService: service, mediaWikiService: nil)

        let first = try await controller.fetchImageData(url: Self.imageURL)
        let second = try await controller.fetchImageData(url: Self.imageURL)

        #expect(first == Self.imageBytes)
        #expect(second == Self.imageBytes)
        // The second call must be served from the in-memory cache, so the service is hit only once.
        #expect(service.dataCallCount == 1)
    }

    @Test
    func fetchImageDataDoesNotShareCacheAcrossDistinctURLs() async throws {
        let service = MockImageService()
        service.dataResult = .success(Self.imageBytes)
        let controller = WMFImageDataController(basicService: service, mediaWikiService: nil)

        _ = try await controller.fetchImageData(url: Self.imageURL)
        _ = try await controller.fetchImageData(url: Self.otherImageURL)

        // Different URLs are cached independently, so each triggers a separate service call.
        #expect(service.dataCallCount == 2)
    }

    @Test
    func fetchImageDataThrowsWhenBasicServiceUnavailable() async throws {
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: nil)

        await #expect(throws: WMFDataControllerError.basicServiceUnavailable) {
            try await controller.fetchImageData(url: Self.imageURL)
        }
    }

    @Test
    func fetchImageDataPropagatesServiceFailure() async throws {
        let service = MockImageService()
        service.dataResult = .failure(WMFServiceError.missingData)
        let controller = WMFImageDataController(basicService: service, mediaWikiService: nil)

        let thrown = await capturedError {
            _ = try await controller.fetchImageData(url: Self.imageURL)
        }

        #expect(thrown as? WMFServiceError == .missingData)
    }

    @Test
    func fetchImageDataDoesNotCacheFailures() async throws {
        let service = MockImageService()
        service.dataResult = .failure(WMFServiceError.missingData)
        let controller = WMFImageDataController(basicService: service, mediaWikiService: nil)

        // First call fails and must not populate the cache.
        _ = await capturedError {
            _ = try await controller.fetchImageData(url: Self.imageURL)
        }

        // A subsequent success for the same URL must therefore hit the service again.
        service.dataResult = .success(Self.imageBytes)
        let data = try await controller.fetchImageData(url: Self.imageURL)

        #expect(data == Self.imageBytes)
        #expect(service.dataCallCount == 2)
    }

    // MARK: - fetchImageInfo

    @Test
    func fetchImageInfoReturnsInfoOnSuccess() async throws {
        let service = MockImageService()
        service.decodableResult = .success(Self.imageInfoJSON)
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: service)

        let info = try await controller.fetchImageInfo(title: "File:Example.jpg", thumbnailWidth: 320, project: Self.enProject)

        #expect(info.title == "File:Example.jpg")
        #expect(info.url == URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg"))
        #expect(info.thumbURL == URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Example.jpg/320px-Example.jpg"))
        #expect(service.decodableGETCallCount == 1)
    }

    @Test
    func fetchImageInfoReturnsUnexpectedResponseWhenNoPages() async throws {
        let service = MockImageService()
        service.decodableResult = .success(Self.emptyPagesJSON)
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: service)

        let thrown = await capturedError {
            _ = try await controller.fetchImageInfo(title: "File:Example.jpg", thumbnailWidth: 320, project: Self.enProject)
        }

        guard let error = thrown as? WMFDataControllerError, case .unexpectedResponse = error else {
            Issue.record("Expected .unexpectedResponse, got \(String(describing: thrown))")
            return
        }
    }

    @Test
    func fetchImageInfoFailsWhenMediaWikiServiceUnavailable() async throws {
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: nil)

        let thrown = await capturedError {
            _ = try await controller.fetchImageInfo(title: "File:Example.jpg", thumbnailWidth: 320, project: Self.enProject)
        }

        // Note: WMFDataControllerError's Equatable only covers a subset of cases, so match the case explicitly.
        guard let error = thrown as? WMFDataControllerError, case .mediaWikiServiceUnavailable = error else {
            Issue.record("Expected .mediaWikiServiceUnavailable, got \(String(describing: thrown))")
            return
        }
    }

    @Test
    func fetchImageInfoFailsForEmptyTitle() async throws {
        let service = MockImageService()
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: service)

        await #expect(throws: WMFDataControllerError.failureCreatingRequestURL) {
            try await controller.fetchImageInfo(title: "", thumbnailWidth: 320, project: Self.enProject)
        }
        // The request is rejected before reaching the service.
        #expect(service.decodableGETCallCount == 0)
    }

    @Test
    func fetchImageInfoPropagatesServiceFailure() async throws {
        let service = MockImageService()
        service.decodableResult = .failure(WMFServiceError.invalidHttpResponse(500))
        let controller = WMFImageDataController(basicService: nil, mediaWikiService: service)

        let thrown = await capturedError {
            _ = try await controller.fetchImageInfo(title: "File:Example.jpg", thumbnailWidth: 320, project: Self.enProject)
        }

        #expect(thrown as? WMFServiceError == .invalidHttpResponse(500))
    }

    // MARK: - Helpers

    private func capturedError(_ body: () async throws -> Void) async -> Error? {
        do {
            try await body()
            return nil
        } catch {
            return error
        }
    }

    private static let imageInfoJSON = Data("""
    {
      "query": {
        "pages": {
          "12345": {
            "title": "File:Example.jpg",
            "imageinfo": [
              {
                "url": "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg",
                "thumburl": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Example.jpg/320px-Example.jpg"
              }
            ]
          }
        }
      }
    }
    """.utf8)

    private static let emptyPagesJSON = Data("""
    { "query": { "pages": {} } }
    """.utf8)
}

/// Minimal `WMFService` mock that returns caller-configured results synchronously and counts calls.
/// `decodableResult` carries JSON bytes that are decoded into the controller's (private) response type
/// via the generic `performDecodableGET`, so the test never needs visibility into that type.
private final class MockImageService: WMFService {
    var dataResult: Result<Data, Error> = .failure(WMFServiceError.missingData)
    var decodableResult: Result<Data, Error> = .failure(WMFServiceError.missingData)
    private(set) var dataCallCount = 0
    private(set) var decodableGETCallCount = 0

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        dataCallCount += 1
        completion(dataResult)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.success(nil))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        decodableGETCallCount += 1
        switch decodableResult {
        case .success(let data):
            do {
                completion(.success(try JSONDecoder().decode(T.self, from: data)))
            } catch {
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func clearCachedData() {}
}

private extension WMFImageDataController {
    func fetchImageInfo(title: String, thumbnailWidth: UInt, project: WMFProject) async throws -> WMFImageInfo {
        try await withCheckedThrowingContinuation { continuation in
            fetchImageInfo(title: title, thumbnailWidth: thumbnailWidth, project: project) { result in
                continuation.resume(with: result)
            }
        }
    }
}
