import Foundation
import Testing
@testable import WMFData

struct WMFGlobalEditorMetricsDataControllerTests {

    private static let startDate = Date(timeIntervalSince1970: 1_764_547_200) // 2025-12-01
    private static let endDate = Date(timeIntervalSince1970: 1_796_083_200) // 2026-12-01

    @Test
    func editCountAddsTheMonths() async throws {
        let service = MockMetricsService(result: .success(Data(#"{"items":[{"timestamp":"2026-01-01","edit_count":3},{"timestamp":"2026-02-01","edit_count":4}]}"#.utf8)))
        let controller = WMFGlobalEditorMetricsDataController(globalUserID: 1, service: service)

        let editCount = try await controller.fetchEditCount(startDate: Self.startDate, endDate: Self.endDate)

        #expect(editCount == 7)
    }

    /// The API sends a 404 for a user without edits in the period. That is 0 edits, so the app shows
    /// the empty edits slide.
    @Test
    func editCountIsZeroWhenTheAPIHasNoData() async throws {
        let service = MockMetricsService(result: .failure(WMFServiceError.invalidHttpResponse(404)))
        let controller = WMFGlobalEditorMetricsDataController(globalUserID: 1, service: service)

        let editCount = try await controller.fetchEditCount(startDate: Self.startDate, endDate: Self.endDate)

        #expect(editCount == 0)
    }

    @Test
    func editedPageViewCountIsZeroWhenTheAPIHasNoData() async throws {
        let service = MockMetricsService(result: .failure(WMFServiceError.invalidHttpResponse(404)))
        let controller = WMFGlobalEditorMetricsDataController(globalUserID: 1, service: service)

        let viewCount = try await controller.fetchEditedPageViewCount(startDate: Self.startDate, endDate: Self.endDate)

        #expect(viewCount == 0)
    }

    /// Other errors still throw, so a failed request never shows the empty edits slide to an editor.
    @Test
    func editCountThrowsForOtherErrors() async throws {
        let service = MockMetricsService(result: .failure(WMFServiceError.invalidHttpResponse(500)))
        let controller = WMFGlobalEditorMetricsDataController(globalUserID: 1, service: service)

        await #expect(throws: WMFServiceError.self) {
            _ = try await controller.fetchEditCount(startDate: Self.startDate, endDate: Self.endDate)
        }
    }
}

private final class MockMetricsService: WMFService {
    private let result: Result<Data, Error>

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(result.flatMap { data in
            Result { try JSONDecoder().decode(T.self, from: data) }
        })
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func clearCachedData() {}
}
