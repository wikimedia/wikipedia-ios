import Testing
@testable import WMFComponents

@MainActor
@Suite
struct WMFRiveSentenceTests {

    private let leading = WMFRiveText(path: "headline1")
    private let middle = WMFRiveText(path: "readDays")
    private let trailing = WMFRiveText(path: "headline2")

    private func fragments(_ format: String, value: String = "47") -> (String?, String?, String?) {
        let sentence = WMFRiveSentence(
            format: format,
            value: value,
            leading: leading,
            middle: middle,
            trailing: trailing
        )
        return (sentence.text[leading], sentence.text[middle], sentence.text[trailing])
    }

    // MARK: - Real translations

    @Test
    func englishSplitsAroundThePlaceholder() {
        let (before, number, after) = fragments("In 2026, you read Wikipedia on %1$@ days.")
        #expect(before == "In 2026, you read Wikipedia on")
        #expect(number == "47")
        #expect(after == "days.")
    }

    /// Chinese puts the number mid-sentence and uses no spaces, so nothing may be trimmed away.
    @Test
    func chineseKeepsEveryCharacter() {
        let (before, number, after) = fragments("2026年，你在%1$@天里阅读了维基百科。")
        #expect(before == "2026年，你在")
        #expect(number == "47")
        #expect(after == "天里阅读了维基百科。")
    }

    @Test
    func arabicKeepsItsSentenceFinalPunctuation() {
        let (before, number, after) = fragments("في عام 2026، ستطالع ويكيبيديا على مدار %1$@ يوماً.")
        #expect(before == "في عام 2026، ستطالع ويكيبيديا على مدار")
        #expect(number == "47")
        #expect(after == "يوماً.")
    }

    @Test
    func spanishSplitsAroundThePlaceholder() {
        let (before, number, after) = fragments("En 2026, leíste Wikipedia durante %1$@ días.")
        #expect(before == "En 2026, leíste Wikipedia durante")
        #expect(number == "47")
        #expect(after == "días.")
    }

    // MARK: - Position

    @Test
    func aPlaceholderAtTheStartLeavesAnEmptyLeadingFragment() {
        let (before, number, after) = fragments("%1$@ days of reading in 2026.")
        #expect(before == "")
        #expect(number == "47")
        #expect(after == "days of reading in 2026.")
    }

    @Test
    func aPlaceholderAtTheEndLeavesAnEmptyTrailingFragment() {
        let (before, number, after) = fragments("Days you read Wikipedia in 2026: %1$@")
        #expect(before == "Days you read Wikipedia in 2026:")
        #expect(number == "47")
        #expect(after == "")
    }

    // MARK: - The trap

    /// Splitting the RENDERED string would search for "6" and find it inside "2026", cutting the
    /// sentence in the wrong place. Splitting the format cannot do that.
    @Test
    func aValueThatAlsoAppearsInTheCopyDoesNotMoveTheSplit() {
        let (before, number, after) = fragments("In 2026, you read Wikipedia on %1$@ days.", value: "6")
        #expect(before == "In 2026, you read Wikipedia on")
        #expect(number == "6")
        #expect(after == "days.")
    }

    // MARK: - Every run is written

    /// A run left out of the dictionary keeps its previous text, which on a reused artboard is
    /// the previous slide's copy or the placeholder baked into the .riv.
    @Test
    func allThreeRunsAreAlwaysWritten() {
        let sentence = WMFRiveSentence(
            format: "%1$@",
            value: "47",
            leading: leading,
            middle: middle,
            trailing: trailing
        )
        #expect(sentence.text.count == 3)
        #expect(sentence.text[leading] == "")
        #expect(sentence.text[trailing] == "")
    }

    @Test
    func anEmptyValueStillWritesTheRun() {
        let (_, number, _) = fragments("In 2026, you read Wikipedia on %1$@ days.", value: "")
        #expect(number == "")
    }

    // MARK: - Split, directly

    /// A translator who wraps the sentence in {{GENDER:$1|...}} gets the variants flattened
    /// into literal pipe-delimited text carrying the token more than once. Two such strings
    /// ship today. Taking the prefix and suffix of the FIRST token keeps the residue visible
    /// instead of deleting sentence text, which components(separatedBy:) would do.
    @Test
    func onlyTheFirstTokenSplits() {
        let result = WMFRiveSentence.split(format: "a %1$@ b %1$@ c")
        #expect(result.leading == "a")
        #expect(result.trailing == "b %1$@ c")
    }

    /// This codebase writes %1$d whenever the value is a count, and the value here IS a count.
    /// 89 runtime keys use %1$d against 115 using %1$@, so matching one spelling would fail
    /// silently in every language.
    @Test
    func aCountStyleTokenSplitsToo() {
        let result = WMFRiveSentence.split(format: "In 2026, you read Wikipedia on %1$d days.")
        #expect(result.leading == "In 2026, you read Wikipedia on")
        #expect(result.trailing == "days.")
    }

    @Test
    func anUnnumberedTokenSplitsToo() {
        let result = WMFRiveSentence.split(format: "read on %@ days")
        #expect(result.leading == "read on")
        #expect(result.trailing == "days")
    }

    // MARK: - Characters that must survive trimming

    /// Khmer separates words with U+200B. In `reference-title` it sits immediately before the
    /// token, so a whitespace trim would delete it and run the words together.
    @Test
    func aZeroWidthSpaceBesideTheTokenIsKept() {
        let result = WMFRiveSentence.split(format: "ឯកសារ\u{200B}យោង\u{200B}%1$@")
        #expect(result.leading == "ឯកសារ\u{200B}យោង\u{200B}")
        #expect(result.trailing == "")
    }

    /// French puts a non-breaking space before some punctuation. Trimming it would change the
    /// typography rather than tidy the fragment.
    @Test
    func nonBreakingSpacesAreKept() {
        let result = WMFRiveSentence.split(format: "sur\u{00A0}%1$@\u{202F}jours")
        #expect(result.leading == "sur\u{00A0}")
        #expect(result.trailing == "\u{202F}jours")
    }

    @Test
    func onlyAsciiSpacesAndTabsAreTrimmed() {
        let result = WMFRiveSentence.split(format: "before \t%1$@\t after")
        #expect(result.leading == "before")
        #expect(result.trailing == "after")
    }
}
