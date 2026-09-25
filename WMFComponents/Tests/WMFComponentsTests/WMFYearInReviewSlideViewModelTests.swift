import Testing
import UIKit
@testable import WMFComponents

@MainActor
@Suite
struct WMFYearInReviewSlideViewModelTests {

    private func slide(
        contentStyle: WMFYearInReviewSlideViewModel.ContentStyle
    ) -> WMFYearInReviewSlideViewModel {
        return WMFYearInReviewSlideViewModel(
            id: "slide",
            loggingID: "slide",
            contentStyle: contentStyle
        )
    }

    @Test
    func contentColorFollowsTheContentStyle() {
        #expect(slide(contentStyle: .light).contentColor == WMFColor.white)
        #expect(slide(contentStyle: .dark).contentColor == WMFColor.gray700)
    }

    @Test
    func prefersLightContentFollowsTheContentStyle() {
        #expect(slide(contentStyle: .light).prefersLightContent)
        #expect(slide(contentStyle: .dark).prefersLightContent == false)
    }

    /// The animation supplies the background, and it is not there yet while the file loads. The
    /// slide shows the dark toolbar background until then, so light is the safe default: dark
    /// controls on the dark background would disappear.
    @Test
    func theDefaultStyleSuitsTheBackgroundBeforeTheAnimationLoads() {
        let model = WMFYearInReviewSlideViewModel(id: "slide", loggingID: "slide")
        #expect(model.contentStyle == .light)
        #expect(model.contentColor == WMFColor.white)
    }

    @Test
    func aSlideKeepsItsIdentityAndDefaults() {
        let model = WMFYearInReviewSlideViewModel(id: "readCount", loggingID: "read_count")
        #expect(model.id == "readCount")
        #expect(model.loggingID == "read_count")
        #expect(model.animation == nil)
        #expect(model.text.isEmpty)
        #expect(model.numbers.isEmpty)
        #expect(model.showsShareButton)
        #expect(model.showsDonateButton)
    }
}
