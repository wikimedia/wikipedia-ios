import Testing
import UIKit
@testable import WMFComponents

@Suite
struct WMFCardGridColumnsTests {

    private let phonePortrait = CGSize(width: 393, height: 852)
    private let phoneLandscape = CGSize(width: 852, height: 393)
    private let padMiniPortrait = CGSize(width: 744, height: 1133)
    private let padPortrait = CGSize(width: 1024, height: 1366)
    private let padLandscape = CGSize(width: 1366, height: 1024)
    // A wide portrait window on any idiom, e.g. iPhone Duo's inner display
    private let widePortraitWindow = CGSize(width: 700, height: 900)
    // A narrow portrait window on iPad, e.g. Split View
    private let narrowPortraitWindow = CGSize(width: 375, height: 1024)

    @Test
    func phonePortraitUsesTwoColumns() {
        #expect(WMFCardGridColumns.count(for: phonePortrait, isAccessibilitySize: false) == 2)
    }

    @Test
    func padPortraitUsesFourColumns() {
        #expect(WMFCardGridColumns.count(for: padPortrait, isAccessibilitySize: false) == 4)
    }

    @Test
    func narrowPadPortraitUsesThreeColumns() {
        // iPad mini keeps 3 so cards don't get cramped
        #expect(WMFCardGridColumns.count(for: padMiniPortrait, isAccessibilitySize: false) == 3)
    }

    @Test
    func widePortraitWindowUsesThreeColumns() {
        // Columns follow the width, not the idiom
        #expect(WMFCardGridColumns.count(for: widePortraitWindow, isAccessibilitySize: false) == 3)
    }

    @Test
    func narrowPortraitWindowUsesTwoColumns() {
        #expect(WMFCardGridColumns.count(for: narrowPortraitWindow, isAccessibilitySize: false) == 2)
    }

    @Test
    func landscapeUsesFourColumns() {
        #expect(WMFCardGridColumns.count(for: padLandscape, isAccessibilitySize: false) == 4)
        #expect(WMFCardGridColumns.count(for: phoneLandscape, isAccessibilitySize: false) == 4)
    }

    @Test
    func accessibilitySizesCollapseToOneColumn() {
        // The single column wins on every size and orientation
        #expect(WMFCardGridColumns.count(for: padLandscape, isAccessibilitySize: true) == 1)
        #expect(WMFCardGridColumns.count(for: phonePortrait, isAccessibilitySize: true) == 1)
    }
}
