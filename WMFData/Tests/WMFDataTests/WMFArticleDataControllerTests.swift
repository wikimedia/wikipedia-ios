import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFArticleDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    @Test
    func fetchWatchStatus() async throws {
        try await withConfiguredEnvironment {
            let controller = WMFArticleDataController()
            let request = try WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: false, needsCategories: false)

            let status = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

            #expect(status.watched)
            #expect(status.userHasRollbackRights == nil)
        }
    }

    @Test
    func fetchWatchStatusWithRollbackRights() async throws {
        try await withConfiguredEnvironment {
            let controller = WMFArticleDataController()
            let request = try WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: true, needsCategories: false)

            let status = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

            #expect(status.watched == false)
            #expect(status.userHasRollbackRights == true)
        }
    }

    private func withConfiguredEnvironment<T>(_ operation: () async throws -> T) async rethrows -> T {
        try await fixture.withGlobalStateLease {
            await fixture.setUp()
            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
                WMFLanguage(languageCode: "en", languageVariantCode: nil)
            ])
            WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
            WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
            await fixture.resetWMFDataTestState()

            do {
                let result = try await operation()
                await fixture.tearDown()
                return result
            } catch {
                await fixture.tearDown()
                throw error
            }
        }
    }
}

private extension WMFArticleDataController {
    func fetchArticleInfo(title: String, project: WMFProject, request: ArticleInfoRequest) async throws -> WMFArticleInfoResponse {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticleInfo(title: title, project: project, request: request) { result in
                continuation.resume(with: result)
            }
        }
    }
}
