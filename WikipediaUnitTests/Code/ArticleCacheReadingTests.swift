@testable import Wikipedia
@testable import WMF
import XCTest

class ArticleCacheReadingTests: XCTestCase {
    let timeout: TimeInterval = 10
    
    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
        ArticleTestHelpers.pullDataFromFixtures(inBundle: wmf_bundle())
        ArticleTestHelpers.stubCompleteMobileHTMLResponse(inBundle: wmf_bundle())
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLCache.shared.removeAllCachedResponses()
        LSNocilla.sharedInstance().stop()
    }
    
    func stub200Responses() {
        
        guard let fixtureData = ArticleTestHelpers.fixtureData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
            .andReturnRawResponse(fixtureData.image)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(200)?
        .withHeaders(["Cache-Control": "public, max-age=86400, s-maxage=86400"])?
            .withBody(fixtureData.html as NSData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(200)?
        .withHeaders(["Cache-Control": "public, max-age=86400, s-maxage=86400"])?
            .withBody(fixtureData.css as NSData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(200)?
        .withHeaders(["Cache-Control": "public, max-age=86400, s-maxage=86400"])?
            .withBody(fixtureData.css as NSData)
    }
    
    func stub304Responses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturn(304)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(304)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(304)
    }
    
    func stub500Responses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(500)
    }
    
    func stub500ZhResponses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://zh.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(500)
    }
    
    func testBasicArticleLoad() {
        
        stub200Responses()
        
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
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: green;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                break
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        
        wait(for: [htmlExpectation], timeout: timeout)
        wait(for: [imageExpectation], timeout: timeout)
        wait(for: [cssExpectation], timeout: timeout)
    }
    
    func testBasicNetworkNotModifiedWithCachedArticle() {
        
        stub304Responses()
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
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                break
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        
        wait(for: [htmlExpectation], timeout: timeout)
        wait(for: [imageExpectation], timeout: timeout)
        wait(for: [cssExpectation], timeout: timeout)
        
    }
    
    func testBasicNetworkFailureWithCachedArticle() {
        
        stub500Responses()
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
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                break
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        
        wait(for: [htmlExpectation], timeout: timeout)
        wait(for: [imageExpectation], timeout: timeout)
        wait(for: [cssExpectation], timeout: timeout)
    }
    
    func testVariantFallbacksUponNetworkFailure() {
        stub500ZhResponses()
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
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//zh.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>美国 (美洲北部国家)</p><img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png\"></body></html>")
                
            case "app://zh.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: blue;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png":
                imageExpectation.fulfill()
            default:
                break
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        
        wait(for: [htmlExpectation], timeout: timeout)
        wait(for: [imageExpectation], timeout: timeout)
        wait(for: [cssExpectation], timeout: timeout)
    }
}
