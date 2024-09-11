@testable import Wikipedia
@testable import WMF
import XCTest

class ArticleCacheReadingManualTests: XCTestCase {
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        ArticleTestHelpers.setup {
            ArticleTestHelpers.pullDataFromFixtures(inBundle: self.wmf_bundle())
            completion(nil)
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLCache.shared.removeAllCachedResponses()
    }
    
    func testBasicNetworkNoConnectionWithCachedArticle() {

       XCTFail("Reminder: these tests need to be on device and in airplane mode, otherwise they won't work. Comment out this failure once this is done and re-run.")

        ArticleTestHelpers.writeCachedPiecesToCachingSystem()

        let basicVC = BasicCachingWebViewController()

        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")

        basicVC.didReceiveDataCallback = { urlSchemeTask, data in

            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }

            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States":

                htmlExpectation.fulfill()

                if let htmlString = String(data: data, encoding: .utf8) {
                    let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                    XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                }

            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":

                cssExpectation.fulfill()

                if let cssString = String(data: data, encoding: .utf8) {
                    let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                    XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
                }
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }

        basicVC.loadViewIfNeeded()

        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
    }
    
   func testVariantFallbacksUponConnectionFailure() {

    XCTFail("Reminder: these tests need to be on device and in airplane mode, otherwise they won't work. Comment out this failure once this is done and re-run.")

    ArticleTestHelpers.writeVariantPiecesToCachingSystem()

        let basicVC = BasicCachingWebViewController()
        basicVC.extraHeaders = ["Accept-Language": "zh-hant"]
        basicVC.articleURL = URL(string: "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD")!

        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")

        basicVC.didReceiveDataCallback = { urlSchemeTask, data in

            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }

            switch urlString {
            case "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD":

                htmlExpectation.fulfill()

                if let htmlString = String(data: data, encoding: .utf8) {
                    let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                    XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//zh.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>美国 (美洲北部国家)</p><img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png\"></body></html>")
                }

            case "app://zh.wikipedia.org/api/rest_v1/data/css/mobile/site":

                cssExpectation.fulfill()

                if let cssString = String(data: data, encoding: .utf8) {
                    let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                    XCTAssertEqual(trimmedCSS, "body {background-color: blue;}", "Unexpected basic HTML content")
                }
            case "app://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }

       basicVC.loadViewIfNeeded()

        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
    }
}
