import Foundation

/// Spreads one localized sentence across the separate Rive text runs that draw it.
///
/// A Rive artboard renders a sentence like "In 2026, you read Wikipedia on 47 days." as three
/// independent text runs so the number can carry its own type. The app can only write each run
/// separately, but a translator has to see the whole sentence, so the sentence is declared once
/// with a placeholder and split here.
///
/// The split follows the placeholder's position in each translation, which is what keeps word
/// order correct. Chinese puts the number mid-sentence and the fragments follow it:
///
///     "2026年，你在%1$@天里阅读了维基百科。"  ->  "2026年，你在" / "47" / "天里阅读了维基百科。"
public struct WMFRiveSentence {

    /// Matches any positional format token the localization pipeline can emit, not just `%1$@`.
    /// Translators write MediaWiki style `$1` and the build converts it, restoring the type
    /// specifier from the English string — so a sentence declared with `%1$d` arrives as `%1$d`.
    /// This codebase reaches for `%1$d` whenever the value is a count, which is exactly this
    /// case, so matching one spelling would fail silently in every language.
    ///
    /// The pattern is the pipeline's own, from `Update Localizations/localization.swift`.
    private static let tokenPattern = #"%([0-9]*)\$?([@dDuUxXoOfeEgGcCsSpaAF]|ll?d)"#

    /// Always carries all three paths, including empty fragments. A run left out of this
    /// dictionary keeps whatever it held before — either the previous slide's text or the
    /// placeholder copy baked into the .riv.
    public let text: [WMFRiveText: String]

    /// - Parameters:
    ///   - format: the localized sentence, containing `placeholder` once.
    ///   - value: the text that replaces the placeholder, already formatted for the locale.
    ///   - leading: the run drawing the text before the placeholder.
    ///   - middle: the run drawing the value.
    ///   - trailing: the run drawing the text after the placeholder.
    public init(
        format: String,
        value: String,
        leading: WMFRiveText,
        middle: WMFRiveText,
        trailing: WMFRiveText
    ) {
        let fragments = Self.split(format: format)

        text = [
            leading: fragments.leading,
            middle: value,
            trailing: fragments.trailing
        ]
    }

    /// Splits on the FORMAT, never on the formatted result. Searching the result for the value
    /// finds the wrong occurrence whenever the surrounding copy contains the same digits — with
    /// a value of "6", "In 2026, ..." splits inside the year.
    ///
    /// Only the first occurrence counts. A translation carrying the token twice would otherwise
    /// have no single split point.
    static func split(format: String) -> (leading: String, trailing: String) {
        guard let range = format.range(of: tokenPattern, options: .regularExpression) else {
            // A translation can reach the app without a token: the pipeline restores the type
            // from English but accepts an unnumbered `%@`, and a dropped token is possible.
            // Keep the whole sentence rather than losing half of it.
            assertionFailure("No format token in Rive sentence \"\(format)\".")
            return (format.trimmedForRive, "")
        }

        return (String(format[format.startIndex..<range.lowerBound]).trimmedForRive,
                String(format[range.upperBound...]).trimmedForRive)
    }
}

private extension String {
    /// Trims ONLY the ASCII space and tab a spaced script leaves beside the token.
    ///
    /// `.whitespaces` and `.whitespacesAndNewlines` are wrong here: they also strip U+200B,
    /// which Khmer uses as a word separator and which sits immediately before the token in
    /// `reference-title`, plus U+00A0 and U+202F, the non-breaking spaces French places before
    /// punctuation. Removing those changes the text rather than tidying it.
    var trimmedForRive: String {
        trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
    }
}
