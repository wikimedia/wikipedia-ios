import Testing
import UIKit
@testable import WMFComponents

@Suite
struct WMFArticlePreviewViewTests {

    @Test
    func compactWindowUsesWindowWidth() {
        #expect(WMFArticlePreviewView.previewWidth(windowWidth: 393, horizontalSizeClass: .compact) == 393)
    }

    @Test
    func regularWindowUsesFixedWidth() {
        // iPad and iPhone Duo's inner display
        #expect(WMFArticlePreviewView.previewWidth(windowWidth: 669, horizontalSizeClass: .regular) == 380)
        #expect(WMFArticlePreviewView.previewWidth(windowWidth: 1024, horizontalSizeClass: .regular) == 380)
    }

    @Test
    func missingWindowUsesFixedWidth() {
        #expect(WMFArticlePreviewView.previewWidth(windowWidth: nil, horizontalSizeClass: .unspecified) == 380)
    }
}
