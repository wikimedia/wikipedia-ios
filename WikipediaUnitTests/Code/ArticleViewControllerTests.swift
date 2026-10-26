import Foundation
import Testing
import UIKit
@testable import Wikipedia

struct ArticleViewControllerTests {

    @Test
    func webContentProcessRecoveryNavigationPolicy() {
        #expect(ArticleViewController.shouldAllowNavigation(type: .backForward))
        #expect(ArticleViewController.shouldAllowNavigation(type: .reload))
        #expect(ArticleViewController.shouldAllowNavigation(type: .other))
        #expect(!ArticleViewController.shouldAllowNavigation(type: .linkActivated))
        #expect(!ArticleViewController.shouldAllowNavigation(type: .formSubmitted))
        #expect(!ArticleViewController.shouldAllowNavigation(type: .formResubmitted))
    }

    @MainActor
    @Test
    func articleVCAccessesSchemeHandler() async throws {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ArticleTestHelpers.setupWithNetworkFixtures {
                continuation.resume()
            }
        }
        defer {
            ArticleTestHelpers.tearDownNetworkFixtures()
        }

        // test that articleVC converts articleURL to proper scheme and sets up SchemeHandler to ensure it is accessed during a load
        let dataStore = await withCheckedContinuation { (continuation: CheckedContinuation<MWKDataStore, Never>) in
            MWKDataStore.createTemporaryDataStore { result in
                continuation.resume(returning: result)
            }
        }

        let theme = Theme.light
        let url = try #require(URL(string: "https://en.wikipedia.org/wiki/Dog"))
        let schemeHandler = MockSchemeHandler(scheme: "app", session: dataStore.session)
        let articleVC = try #require(ArticleViewController(articleURL: url, dataStore: dataStore, theme: theme, source: .undefined, schemeHandler: schemeHandler))
        defer {
            UIApplication.shared.workaroundKeyWindow?.rootViewController = nil
            dataStore.clearTemporaryCache()
            dataStore.session.teardown()
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            articleVC.initialSetupCompletion = {
                continuation.resume()
            }

            UIApplication.shared.workaroundKeyWindow?.rootViewController = articleVC
        }

        #expect(schemeHandler.accessed, "SchemeHandler was not accessed during article load.")
    }
}
