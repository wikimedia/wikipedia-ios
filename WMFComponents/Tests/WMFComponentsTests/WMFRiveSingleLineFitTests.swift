import Testing
@testable import WMFComponents

@MainActor
@Suite
struct WMFRiveSingleLineFitTests {

    @Test
    func aValueThatFitsKeepsItsSize() {
        #expect(WMFRiveSingleLineFit.scale(textWidth: 100, maximumWidth: 344) == 1)
    }

    @Test
    func anEmptyValueKeepsItsSize() {
        #expect(WMFRiveSingleLineFit.scale(textWidth: 0, maximumWidth: 344) == 1)
    }

    /// A value that is too wide becomes as wide as the box less the margin.
    @Test
    func aWideValueScalesToTheBoxLessTheMargin() {
        let scale = WMFRiveSingleLineFit.scale(textWidth: 660, maximumWidth: 344)
        let fittedWidth = 660 * scale
        #expect(scale < 1)
        #expect(abs(fittedWidth - 344 * (1 - WMFRiveSingleLineFit.widthMargin)) < 0.001)
    }

    /// Rive scales the outlines of the supplied font, so the width is linear in the font size.
    @Test
    func theMeasuredWidthIsLinearInTheFontSize() throws {
        let small = try #require(WMFRiveSingleLineFit.width(of: "2,376,881,343", fontAssetName: "SanSerifFont", fontSize: 45))
        let large = try #require(WMFRiveSingleLineFit.width(of: "2,376,881,343", fontAssetName: "SanSerifFont", fontSize: 90))
        #expect(small > 0)
        #expect(abs(large - 2 * small) < 0.001)
    }

    @Test
    func aLongerValueIsWider() throws {
        let short = try #require(WMFRiveSingleLineFit.width(of: "14", fontAssetName: "SanSerifFont", fontSize: 90))
        let long = try #require(WMFRiveSingleLineFit.width(of: "2,376,881,343", fontAssetName: "SanSerifFont", fontSize: 90))
        #expect(long > short)
    }

    /// The numbers of the total articles slide fit at the size in the file. The collective numbers do not.
    @Test
    func onlyLongNumbersAreScaled() throws {
        let shortWidth = try #require(WMFRiveSingleLineFit.width(of: "43,740", fontAssetName: "SanSerifFont", fontSize: 90))
        let longWidth = try #require(WMFRiveSingleLineFit.width(of: "2,376,881,343", fontAssetName: "SanSerifFont", fontSize: 90))
        #expect(WMFRiveSingleLineFit.scale(textWidth: shortWidth, maximumWidth: 344) == 1)
        #expect(WMFRiveSingleLineFit.scale(textWidth: longWidth, maximumWidth: 344) < 1)
    }

    @Test
    func anAssetWithoutASystemFontHasNoWidth() {
        #expect(WMFRiveSingleLineFit.width(of: "14", fontAssetName: "NotInTheFile", fontSize: 90) == nil)
    }
}
