import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFArticleDataControllerTests: XCTestCase {
    
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    
    override func setUp() async throws {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages:[
            WMFLanguage(languageCode: "en", languageVariantCode: nil)
        ])
        WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
    
    func testFetchWatchStatus() async throws {
        let controller = WMFArticleDataController()

        guard let request = try? WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: false, needsCategories: false) else {
            return
        }
        
        let statusToTest = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

         XCTAssertTrue(statusToTest.watched)
         XCTAssertNil(statusToTest.userHasRollbackRights)
     }

     func testFetchWatchStatusWithRollbackRights() async throws {
         let controller = WMFArticleDataController()

         guard let request = try? WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: true, needsCategories: false) else {
             return
         }
         
         let statusToTest = try await controller.fetchArticleInfo(title: "Cat", project: enProject, request: request)

         XCTAssertFalse(statusToTest.watched)
         XCTAssertTrue((statusToTest.userHasRollbackRights ?? false))
     }
}
