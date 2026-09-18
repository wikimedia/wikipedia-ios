import Testing
import UIKit
@testable import WMFComponents

@MainActor
@Suite
struct WMFYearInReviewSlideViewModelTests {

    private func slide(
        backgroundColor: UIColor,
        contentStyle: WMFYearInReviewSlideViewModel.ContentStyle = .automatic
    ) -> WMFYearInReviewSlideViewModel {
        return WMFYearInReviewSlideViewModel(
            id: "slide",
            loggingID: "slide",
            backgroundColor: backgroundColor,
            contentStyle: contentStyle
        )
    }

    @Test
    func aDarkBackgroundAsksForLightContent() {
        let navy = UIColor(red: 0.063, green: 0.141, blue: 0.243, alpha: 1)
        #expect(slide(backgroundColor: navy).prefersLightContent)
        #expect(slide(backgroundColor: .black).prefersLightContent)
    }

    @Test
    func aLightBackgroundAsksForDarkContent() {
        let cream = UIColor(red: 0.98, green: 0.976, blue: 0.961, alpha: 1)
        #expect(slide(backgroundColor: cream).prefersLightContent == false)
        #expect(slide(backgroundColor: .white).prefersLightContent == false)
    }

    /// Green weighs far more than blue in the luminance formula, so two colors with the same
    /// raw component total can land on opposite sides. A plain average would get these wrong.
    @Test
    func luminanceIsWeightedByChannel() {
        #expect(slide(backgroundColor: .blue).prefersLightContent)
        #expect(slide(backgroundColor: .green).prefersLightContent == false)
    }

    @Test
    func anExplicitStyleOverridesTheBackground() {
        #expect(slide(backgroundColor: .white, contentStyle: .light).prefersLightContent)
        #expect(slide(backgroundColor: .black, contentStyle: .dark).prefersLightContent == false)
    }

    @Test
    func contentColorFollowsTheContentStyle() {
        #expect(slide(backgroundColor: .black).contentColor == WMFColor.white)
        #expect(slide(backgroundColor: .white).contentColor == WMFColor.gray700)
    }

    /// The mint and tan palettes both read as light, so the chrome must stay dark on them.
    /// This is the case that shipped wrong once: dark controls on a dark slide.
    @Test
    func theDesignPalettesResolveAsExpected() {
        let mint = UIColor(red: 0.839, green: 0.937, blue: 0.898, alpha: 1)
        let tan = UIColor(red: 0.929, green: 0.890, blue: 0.784, alpha: 1)
        let blue = UIColor(red: 0.165, green: 0.294, blue: 0.553, alpha: 1)

        #expect(slide(backgroundColor: mint).contentColor == WMFColor.gray700)
        #expect(slide(backgroundColor: tan).contentColor == WMFColor.gray700)
        #expect(slide(backgroundColor: blue).contentColor == WMFColor.white)
    }

    @Test
    func aSlideKeepsItsIdentityAndDefaults() {
        let model = WMFYearInReviewSlideViewModel(id: "readCount", loggingID: "read_count", backgroundColor: .white)
        #expect(model.id == "readCount")
        #expect(model.loggingID == "read_count")
        #expect(model.animation == nil)
        #expect(model.text.isEmpty)
        #expect(model.numbers.isEmpty)
        #expect(model.showsShareButton)
        #expect(model.showsDonateButton)
    }
}
