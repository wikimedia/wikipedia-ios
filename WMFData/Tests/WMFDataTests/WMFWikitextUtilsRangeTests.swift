import Foundation
import Testing
@testable import WMFData

/// `WMFWikitextUtilsTests` (XCTest) covers image insertion. This suite covers the other half of the
/// utility: locating selected article text back inside raw wikitext, which has to see through
/// bold markers, links and templates that the rendered HTML does not contain.
@Suite
struct WMFWikitextUtilsRangeTests {

    private func range(before: String, target: String, after: String, in wikitext: String) -> NSRange {
        WMFWikitextUtils.rangeOf(
            htmlInfo: WMFWikitextUtils.HtmlInfo(textBeforeTargetText: before, targetText: target, textAfterTargetText: after),
            inWikitext: wikitext
        )
    }

    /// No selection means nothing to locate, and the caller gets NSNotFound rather than a zero range
    /// that would read as "found it at the start".
    @Test
    func emptyTargetTextIsNotFound() {
        let result = range(before: "The ", target: "", after: " sat", in: "The cat sat on the mat")

        #expect(result.location == NSNotFound)
        #expect(result.length == 0)
    }

    /// Text that does not occur in the wikitext at all is also NSNotFound.
    @Test
    func targetTextAbsentFromWikitextIsNotFound() {
        let result = range(before: "The ", target: "zebra", after: " sat", in: "The cat sat on the mat")

        #expect(result.location == NSNotFound)
    }

    /// The simple case: one plain occurrence, no markup in the way.
    @Test
    func plainTargetTextResolvesToItsExactRange() {
        let wikitext = "The cat sat on the mat"
        let result = range(before: "The ", target: "cat sat", after: " on the mat", in: wikitext)

        #expect((wikitext as NSString).substring(with: result) == "cat sat")
        #expect(result.location == (wikitext as NSString).range(of: "cat sat").location)
    }

    /// The reason this utility exists: the rendered HTML the user selected from has no apostrophes,
    /// so the returned range has to stretch over the bold markers to cover the same words.
    @Test
    func targetTextSpanningBoldMarkupIsMatchedThroughIt() {
        let wikitext = "The '''cat''' sat on the mat"
        let result = range(before: "The ", target: "cat sat", after: " on the mat", in: wikitext)

        #expect((wikitext as NSString).substring(with: result) == "cat''' sat")
    }

    /// Same idea across a piped wikilink, where the rendered text is only the label.
    @Test
    func targetTextSpanningAWikilinkIsMatchedThroughIt() {
        let wikitext = "the [[Domestication of animals|domesticated]] species in the family"
        let result = range(before: "the ", target: "domesticated species", after: " in the family", in: wikitext)

        #expect((wikitext as NSString).substring(with: result) == "domesticated]] species")
    }

    /// When the same phrase occurs twice, the surrounding words decide which one is meant. This pair
    /// of tests uses one wikitext and only changes the context, so the context is provably what picks
    /// the match rather than position or ordering.
    @Test
    func contextSelectsTheEarlierOfTwoIdenticalOccurrences() {
        let wikitext = "The dog barked loudly here. The cat sat quietly. Later the cat sat again."
        let result = range(
            before: "The dog barked loudly here. The ",
            target: "cat sat",
            after: " quietly.",
            in: wikitext
        )

        #expect(result.location == (wikitext as NSString).range(of: "cat sat").location)
    }

    @Test
    func contextSelectsTheLaterOfTwoIdenticalOccurrences() {
        let wikitext = "The dog barked loudly here. The cat sat quietly. Later the cat sat again."
        let result = range(
            before: "The cat sat quietly. Later the ",
            target: "cat sat",
            after: " again.",
            in: wikitext
        )

        #expect(result.location == (wikitext as NSString).range(of: "cat sat", options: .backwards).location)
    }
}
