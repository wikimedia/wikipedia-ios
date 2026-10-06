import Testing
import UIKit
@testable import WMFComponents

@MainActor
@Suite
struct WMFRiveTextFitTests {

    private func fit(
        fontAssetName: String = "SanSerifFont",
        maximumWidth: Double = 344,
        maximumLines: Int = 1,
        minimumScale: Double = 0
    ) -> WMFRiveTextFit {
        WMFRiveTextFit(
            text: WMFRiveText(path: "data"),
            fontAssetName: fontAssetName,
            maximumWidth: maximumWidth,
            maximumLines: maximumLines,
            minimumScale: minimumScale,
            globalViewModelName: "GlobalProperties",
            fontSize: WMFRiveNumber(path: "fontSize"),
            lineHeight: WMFRiveNumber(path: "lineHeight")
        )
    }

    private let longNumber = "2,376,881,343"
    private let longCopy = String(repeating: "Damit gehörst du zu den besten Leserinnen und Lesern weltweit. ", count: 4)

    // MARK: - One line

    @Test
    func aLineThatFitsKeepsItsSize() {
        #expect(WMFRiveTextFit.singleLineScale(textWidth: 100, availableWidth: 330) == 1)
        #expect(WMFRiveTextFit.singleLineScale(textWidth: 0, availableWidth: 330) == 1)
    }

    @Test
    func aWideLineScalesToTheAvailableWidth() {
        let scale = WMFRiveTextFit.singleLineScale(textWidth: 660, availableWidth: 330)
        #expect(abs(scale - 0.5) < 0.000_1)
    }

    /// The numbers of the total articles slide fit at the size in the file. The collective numbers do not.
    @Test
    func onlyLongNumbersAreScaled() throws {
        #expect(try #require(fit().scale(for: "43,740", fontSize: 90)) == 1)
        #expect(try #require(fit().scale(for: longNumber, fontSize: 90)) < 1)
    }

    /// Rive scales the outlines of the supplied font, so the width is linear in the font size.
    @Test
    func theMeasuredWidthIsLinearInTheFontSize() throws {
        let font = try #require(WMFRiveWorkerProvider.substituteFont(forAssetNamed: "SanSerifFont"))
        let small = WMFRiveTextFit.width(of: longNumber, font: font, fontSize: 45)
        let large = WMFRiveTextFit.width(of: longNumber, font: font, fontSize: 90)
        #expect(small > 0)
        #expect(abs(large - 2 * small) < 0.001)
    }

    @Test
    func aFloorStopsTheScale() throws {
        #expect(try #require(fit(minimumScale: 0.9).scale(for: longNumber, fontSize: 90)) == 0.9)
    }

    // MARK: - Several lines

    @Test
    func theLineCountGrowsWithTheFontSize() throws {
        let font = try #require(WMFRiveWorkerProvider.substituteFont(forAssetNamed: "SerifFont"))
        let small = WMFRiveTextFit.lineCount(of: longCopy, font: font, fontSize: 12, availableWidth: 290)
        let large = WMFRiveTextFit.lineCount(of: longCopy, font: font, fontSize: 24, availableWidth: 290)
        #expect(small >= 1)
        #expect(large > small)
    }

    @Test
    func shortCopyKeepsItsSize() throws {
        let fit = fit(fontAssetName: "SerifFont", maximumWidth: 290, maximumLines: 3, minimumScale: 0.75)
        #expect(try #require(fit.scale(for: "Your total article count:", fontSize: 24)) == 1)
    }

    /// Long copy becomes smaller until it fits its lines, or until the floor.
    @Test
    func longCopyBecomesSmallerToTheFloor() throws {
        let fit = fit(fontAssetName: "SerifFont", maximumWidth: 290, maximumLines: 4, minimumScale: 0.75)
        let font = try #require(WMFRiveWorkerProvider.substituteFont(forAssetNamed: "SerifFont"))
        let scale = try #require(fit.scale(for: longCopy, fontSize: 16))

        #expect(scale < 1)
        #expect(scale >= 0.75)
        let lines = WMFRiveTextFit.lineCount(of: longCopy, font: font, fontSize: 16 * scale, availableWidth: 290 * (1 - WMFRiveTextFit.widthMargin))
        #expect(lines <= 4 || scale == 0.75)
    }

    @Test
    func anAssetWithoutASystemFontHasNoScale() {
        #expect(fit(fontAssetName: "NotInTheFile").scale(for: "14", fontSize: 90) == nil)
    }
}
