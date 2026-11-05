import Foundation
import Testing
@testable import WMFData

/// `rangeOf(htmlInfo:inWikitext:)` scores every occurrence of the target text by how well the words
/// around it line up with the words around the user's selection, and must return the highest scorer.
/// With only two occurrences, "beats the first one" and "beats every other one" are the same thing,
/// so these tests use three occurrences whose context scores are deliberately out of order.
@Suite
struct WMFWikitextUtilsBestMatchTests {

    // Every occurrence of "cat" has at least six words of its own on each side, which is the scoring
    // window, so no occurrence's score can pick up context words from a neighbouring sentence.
    private let noContext = "one two three four five six cat seven eight nine ten eleven twelve."
    private let fullContext = "aa bb cc alpha beta gamma cat delta epsilon zeta dd ee ff."
    private let partialContext = "gg hh ii jj kk gamma cat delta ll mm nn oo pp."

    private func rangeOfCat(in wikitext: String) -> NSRange {
        WMFWikitextUtils.rangeOf(
            htmlInfo: WMFWikitextUtils.HtmlInfo(textBeforeTargetText: "alpha beta gamma ", targetText: "cat", textAfterTargetText: " delta epsilon zeta"),
            inWikitext: wikitext
        )
    }

    private func location(of sentence: String, in wikitext: String) -> Int {
        let sentenceLocation = (wikitext as NSString).range(of: sentence).location
        return sentenceLocation + (sentence as NSString).range(of: "cat").location
    }

    /// Scores in order: none, full, partial. The full-context match must win even though a later
    /// match also beats the first one.
    @Test
    func bestMatchWinsWhenALaterWeakerMatchAlsoBeatsTheFirst() {
        let wikitext = [noContext, fullContext, partialContext].joined(separator: " ")

        let result = rangeOfCat(in: wikitext)

        #expect(result.location == location(of: fullContext, in: wikitext))
        #expect(result.length == 3)
    }

    /// Same three sentences with the best one last, so a fix that simply kept the first improvement
    /// would fail here instead.
    @Test
    func bestMatchWinsWhenItComesAfterAWeakerImprovement() {
        let wikitext = [noContext, partialContext, fullContext].joined(separator: " ")

        let result = rangeOfCat(in: wikitext)

        #expect(result.location == location(of: fullContext, in: wikitext))
        #expect(result.length == 3)
    }

    /// Two occurrences with identical context score the same; the earlier one is kept, as it was
    /// before the scoring fix.
    @Test
    func tiedScoresKeepTheEarlierMatch() {
        let wikitext = [noContext, partialContext, partialContext].joined(separator: " ")

        let result = rangeOfCat(in: wikitext)

        #expect(result.location == location(of: partialContext, in: wikitext))
    }
}
