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

    @Test
    func phonePortraitUsesTwoColumns() {
        #expect(WMFCardGridColumns.count(for: phonePortrait, isAccessibilitySize: false, idiom: .phone) == 2)
    }

    @Test
    func padPortraitUsesFourColumns() {
        #expect(WMFCardGridColumns.count(for: padPortrait, isAccessibilitySize: false, idiom: .pad) == 4)
    }

    @Test
    func narrowPadPortraitUsesThreeColumns() {
        // iPad mini keeps 3 so cards don't get cramped
        #expect(WMFCardGridColumns.count(for: padMiniPortrait, isAccessibilitySize: false, idiom: .pad) == 3)
    }

    @Test
    func landscapeUsesFourColumns() {
        #expect(WMFCardGridColumns.count(for: padLandscape, isAccessibilitySize: false, idiom: .pad) == 4)
        #expect(WMFCardGridColumns.count(for: phoneLandscape, isAccessibilitySize: false, idiom: .phone) == 4)
    }

    @Test
    func accessibilitySizesCollapseToOneColumn() {
        // The single column wins on every idiom and orientation
        #expect(WMFCardGridColumns.count(for: padLandscape, isAccessibilitySize: true, idiom: .pad) == 1)
        #expect(WMFCardGridColumns.count(for: phonePortrait, isAccessibilitySize: true, idiom: .phone) == 1)
    }
}
