import Testing
import UIKit
import SwiftUI
@testable import WMFComponents

@MainActor
@Suite
struct WMFYearInReviewHighlightsTests {

    private static let strings = WMFYearInReviewHighlights.LocalizedStrings(
        title: "Wikipedia Year in Review 2026",
        articlesReadLabel: "Number of articles read:",
        minutesReadLabel: "Total minutes read:",
        rotationLabel: "Articles in my rotation:",
        rabbitHoleLabel: "Longest rabbit hole:",
        nicheCategoryLabel: "Niche category explored:",
        createdWith: "Created with the Wikipedia app"
    )

    private static func highlights(rotation: [String] = ["Moon", "Cat", "Paris", "Europe"]) -> WMFYearInReviewHighlights {
        WMFYearInReviewHighlights(
            articlesRead: 1_253_938,
            minutesRead: 1_253_937,
            rotation: rotation,
            rabbitHole: .init(firstTitle: "Frida Kahlo", lastTitle: "Diego Rivera"),
            nicheCategory: "Executed female serial killers",
            localizedStrings: strings
        )
    }

    @Test
    func theRotationKeepsTheFirstThreeArticles() {
        #expect(Self.highlights().rotation == ["Moon", "Cat", "Paris"])
    }

    @Test
    func eachHighlightCounts() {
        #expect(Self.highlights().highlightCount == 5)
        #expect(Self.highlights(rotation: []).highlightCount == 4)
    }

    @Test
    func twoHighlightsAreEnoughToShare() {
        let two = WMFYearInReviewHighlights(articlesRead: 3, minutesRead: 1, rotation: [], rabbitHole: nil, nicheCategory: nil, localizedStrings: Self.strings)
        let one = WMFYearInReviewHighlights(articlesRead: 3, minutesRead: nil, rotation: [], rabbitHole: nil, nicheCategory: nil, localizedStrings: Self.strings)
        #expect(two.isShareable)
        #expect(one.isShareable == false)
    }

    @Test(arguments: [LayoutDirection.leftToRight, .rightToLeft])
    func theImageIsNineBySixteen(layoutDirection: LayoutDirection) throws {
        let image = try #require(WMFYearInReviewHighlightsShareView.image(for: Self.highlights(), layoutDirection: layoutDirection))
        #expect(image.size.width * image.scale == 1080)
        #expect(image.size.height * image.scale == 1920)
    }
}
