import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
struct WMFArticleDataControllerTests {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    init() {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
            WMFLanguage(languageCode: "en", languageVariantCode: nil)
        ])
        WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    @Test
    func fetchWatchStatus() async throws {
        let controller = WMFArticleDataController()
        let request = try WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: false, needsCategories: false)

        let status = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

        #expect(status.watched)
        #expect(status.userHasRollbackRights == nil)
    }

    @Test
    func fetchWatchStatusWithRollbackRights() async throws {
        let controller = WMFArticleDataController()
        let request = try WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: true, needsCategories: false)

        let status = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

        #expect(status.watched == false)
        #expect(status.userHasRollbackRights == true)
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
