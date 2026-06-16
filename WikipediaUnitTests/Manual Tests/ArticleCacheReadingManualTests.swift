import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

@MainActor
final class ArticleCacheReadingManualTests {
    
    init() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ArticleTestHelpers.setup {
                continuation.resume()
            }
        }

        ArticleTestHelpers.pullDataFromFixtures(inBundle: Bundle(for: ArticleCacheReadingManualTestBundleToken.self))
    }

    deinit {
        ArticleTestHelpers.tearDown()
    }

    private func loadResponses(
        for basicVC: BasicCachingWebViewController,
        expectedURLs: Set<String>
    ) async -> [String: Data] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[String: Data], Never>) in
            var responses: [String: Data] = [:]
            var didResume = false

            basicVC.didReceiveDataCallback = { urlSchemeTask, data in
                guard !didResume else {
                    return
                }

                guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                    Issue.record("Unable to determine urlString from scheme task")
                    return
                }

                guard expectedURLs.contains(urlString) else {
                    Issue.record("Unexpected scheme task callback")
                    return
                }

                responses[urlString] = data
                guard expectedURLs.allSatisfy({ responses[$0] != nil }) else {
                    return
                }

                didResume = true
                basicVC.didReceiveDataCallback = nil
                continuation.resume(returning: responses)
            }

            basicVC.loadViewIfNeeded()
        }
    }

    private func data(
        from responses: [String: Data],
        for urlString: String
    ) throws -> Data {
        try #require(responses[urlString], "Missing scheme task response for \(urlString)")
    }

    private func trimmedString(
        from responses: [String: Data],
        for urlString: String
    ) throws -> String {
        let data = try data(from: responses, for: urlString)
        let string = try #require(String(data: data, encoding: .utf8))
        return String(string.filter { !"\n\t\r".contains($0) })
    }

    @Test(.timeLimit(.minutes(1)))
    func basicNetworkNoConnectionWithCachedArticle() async throws {
        defer {
            URLCache.shared.removeAllCachedResponses()
        }

        try #require(Bool(false), "Reminder: these tests need to be on device and in airplane mode, otherwise they won't work. Comment out this failure once this is done and re-run.")

        ArticleTestHelpers.writeCachedPiecesToCachingSystem()

        let basicVC = BasicCachingWebViewController()
        let htmlURLString = "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States"
        let imageURLString = "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png"
        let cssURLString = "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site"
        let responses = await loadResponses(
            for: basicVC,
            expectedURLs: [
                htmlURLString,
                imageURLString,
                cssURLString
            ]
        )

        let html = try trimmedString(from: responses, for: htmlURLString)
        #expect(html == "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
        _ = try data(from: responses, for: imageURLString)
        let css = try trimmedString(from: responses, for: cssURLString)
        #expect(css == "body {background-color: red;}", "Unexpected basic HTML content")
    }
    
    @Test(.timeLimit(.minutes(1)))
    func variantFallbacksUponConnectionFailure() async throws {
        defer {
            URLCache.shared.removeAllCachedResponses()
        }

        try #require(Bool(false), "Reminder: these tests need to be on device and in airplane mode, otherwise they won't work. Comment out this failure once this is done and re-run.")

        ArticleTestHelpers.writeVariantPiecesToCachingSystem()

        let basicVC = BasicCachingWebViewController()
        basicVC.extraHeaders = ["Accept-Language": "zh-hant"]
        basicVC.articleURL = try #require(URL(string: "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD"))

        let htmlURLString = "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD"
        let imageURLString = "app://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png"
        let cssURLString = "app://zh.wikipedia.org/api/rest_v1/data/css/mobile/site"
        let responses = await loadResponses(
            for: basicVC,
            expectedURLs: [
                htmlURLString,
                imageURLString,
                cssURLString
            ]
        )

        let html = try trimmedString(from: responses, for: htmlURLString)
        #expect(html == "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//zh.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>美国 (美洲北部国家)</p><img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png\"></body></html>")
        _ = try data(from: responses, for: imageURLString)
        let css = try trimmedString(from: responses, for: cssURLString)
        #expect(css == "body {background-color: blue;}", "Unexpected basic HTML content")
    }
}

private final class ArticleCacheReadingManualTestBundleToken {}
