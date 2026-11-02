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
        rotationRank: { "(\($0))" },
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

    /// With little content, the image is the 9:16 size of the slide image.
    @Test(arguments: [LayoutDirection.leftToRight, .rightToLeft])
    func aShortImageIsNineBySixteen(layoutDirection: LayoutDirection) throws {
        let highlights = WMFYearInReviewHighlights(articlesRead: 3, minutesRead: 1, rotation: [], rabbitHole: nil, nicheCategory: nil, localizedStrings: Self.strings)
        let image = try #require(WMFYearInReviewHighlightsShareView.image(for: highlights, layoutDirection: layoutDirection))
        #expect(image.size.width * image.scale == 1080)
        #expect(image.size.height * image.scale == 1920)
    }

    /// Long titles do not shrink or cut anything. The image grows taller, and keeps its width.
    @Test
    func longContentMakesTheImageTaller() throws {
        let long = "History of the Byzantine Empire from the reign of Justinian to the Fourth Crusade"
        let highlights = WMFYearInReviewHighlights(
            articlesRead: 123_456_789,
            minutesRead: 987_654_321,
            rotation: [long, long, long],
            rabbitHole: .init(firstTitle: long, lastTitle: long),
            nicheCategory: long,
            localizedStrings: .init(title: "Wikipedia-Jahresrückblick 2026", articlesReadLabel: "Anzahl der gelesenen Artikel:", minutesReadLabel: "Gesamtzahl der Leseminuten:", rotationLabel: "Artikel, die ich immer wieder gelesen habe:", rotationRank: { "(\($0))" }, rabbitHoleLabel: "Längster Kaninchenbau der Verlinkungen:", nicheCategoryLabel: "Erkundete Nischenkategorie:", createdWith: "Erstellt mit der Wikipedia-App")
        )
        let image = try #require(WMFYearInReviewHighlightsShareView.image(for: highlights, layoutDirection: .leftToRight))
        #expect(image.size.width * image.scale == 1080)
        #expect(image.size.height * image.scale > 1920)
    }
}
