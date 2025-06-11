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
    
    func testFetchWatchStatus() {
        let controller = WMFArticleDataController()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
        var statusToTest: WMFArticleDataController.WMFArticleInfoResponse?
        
        guard let request = try? WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: false, needsCategories: false) else {
            return
        }
        
        controller.fetchArticleInfo(title: "Cat", project: enProject, request: request) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertTrue(statusToTest.watched)
         XCTAssertNil(statusToTest.userHasRollbackRights)
     }

     func testFetchWatchStatusWithRollbackRights() {
         let controller = WMFArticleDataController()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
         var statusToTest: WMFArticleDataController.WMFArticleInfoResponse?
         
         guard let request = try? WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: true, needsRollbackRights: true, needsCategories: false) else {
             return
         }
         
         controller.fetchArticleInfo(title: "Cat", project: enProject, request: request) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertFalse(statusToTest.watched)
         XCTAssertTrue((statusToTest.userHasRollbackRights ?? false))
     }
}
