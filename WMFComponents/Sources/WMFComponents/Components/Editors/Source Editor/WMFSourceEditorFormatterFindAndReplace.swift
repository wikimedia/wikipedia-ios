// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorMatch = NSAttributedString.Key("WMFSourceEditorCustomKeyMatch")
    static let wmfSourceEditorSelectedMatch = NSAttributedString.Key("WMFSourceEditorCustomKeySelectedMatch")
    static let wmfSourceEditorReplacedMatch = NSAttributedString.Key("WMFSourceEditorCustomKeyReplacedMatch")
}

class WMFSourceEditorFormatterFindAndReplace: WMFSourceEditorFormatter {

    private(set) var selectedMatchIndex: Int?

    private var searchText: String?
    private var searchRegex: NSRegularExpression?

    private var fullAttributedString: NSAttributedString?
    private var matchRanges: [NSRange] = []
    private var replacedRanges: [NSRange] = []

    private var matchAttributes: [NSAttributedString.Key: Any]
    private var selectedMatchAttributes: [NSAttributedString.Key: Any]
    private var replacedMatchAttributes: [NSAttributedString.Key: Any]

    // MARK: - Getters and Setters

    var matchCount: Int {
        matchRanges.count
    }

    var selectedMatchRange: NSRange? {
        guard let selectedMatchIndex, selectedMatchIndex < matchRanges.count else {
            return nil
        }
        return matchRanges[selectedMatchIndex]
    }

    var lastReplacedRange: NSRange? {
        replacedRanges.last
    }

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        matchAttributes = [
            .foregroundColor: colors.matchForegroundColor,
            .backgroundColor: colors.matchBackgroundColor,
            .wmfSourceEditorMatch: true
        ]
        selectedMatchAttributes = [
            .foregroundColor: colors.matchForegroundColor,
            .backgroundColor: colors.selectedMatchBackgroundColor,
            .wmfSourceEditorSelectedMatch: true
        ]
        replacedMatchAttributes = [
            .foregroundColor: colors.matchForegroundColor,
            .backgroundColor: colors.replacedMatchBackgroundColor,
            .wmfSourceEditorReplacedMatch: true
        ]
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard let fullAttributedString else { return }
        
        // This override is only needed for TextKit 2. The attributed string passed in here is regenerated fresh via the textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) delegate method, so we need to reapply attributes.

        // TextKit 2 only passes in the paragraph attributed string here, as opposed to the full document attributed string with TextKit 1. This conditional singles out TextKit 2.

        // Note: test this for a one line document, I think it breaks
        if range.location == 0 && range.length < fullAttributedString.length {
            let paragraphRange = (fullAttributedString.string as NSString).range(of: attributedString.string)

            for (idx, matchRange) in matchRanges.enumerated() {
                // Find matches that only lie in paragraph range
                if NSIntersectionRange(paragraphRange, matchRange).length > 0 {
                    let attributes = idx == selectedMatchIndex ? selectedMatchAttributes : matchAttributes
                    
                    // Translate full string match back to paragraph match range
                    let paragraphMatchRange = NSRange(location: matchRange.location - paragraphRange.location, length: matchRange.length)
                    
                    // Then reapply attributes to paragraph match range.
                    if canEvaluateAttributedString(attributedString, againstRange: paragraphMatchRange) {
                        resetKeys(for: attributedString, range: paragraphMatchRange)
                        attributedString.addAttributes(attributes, range: paragraphMatchRange)
                    }
                }
            }

            for replacedRange in replacedRanges {
                // Find matches that only lie in paragraph range
                if NSIntersectionRange(paragraphRange, replacedRange).length > 0 {
                    
                    // Translate full string match back to paragraph match range
                    let paragraphMatchRange = NSRange(location: replacedRange.location - paragraphRange.location, length: replacedRange.length)
                    
                    // Then reapply attributes to paragraph match range.
                    if canEvaluateAttributedString(attributedString, againstRange: paragraphMatchRange) {
                        resetKeys(for: attributedString, range: paragraphMatchRange)
                        attributedString.addAttributes(replacedMatchAttributes, range: paragraphMatchRange)
                    }
                }
            }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        matchAttributes[.backgroundColor] = colors.matchBackgroundColor
        selectedMatchAttributes[.backgroundColor] = colors.selectedMatchBackgroundColor
        replacedMatchAttributes[.backgroundColor] = colors.replacedMatchBackgroundColor

        let keys: [(NSAttributedString.Key, [NSAttributedString.Key: Any])] = [
            (.wmfSourceEditorMatch, matchAttributes),
            (.wmfSourceEditorSelectedMatch, selectedMatchAttributes),
            (.wmfSourceEditorReplacedMatch, replacedMatchAttributes)
        ]

        for (key, attrs) in keys {
            attributedString.enumerateAttribute(key, in: range) { value, localRange, _ in
                if (value as? Bool) == true {
                    attributedString.addAttributes(attrs, range: localRange)
                }
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
    }

    // MARK: - Public

    func startMatchSession(with fullAttributedString: NSMutableAttributedString, searchText: String) {
        self.searchText = searchText
        self.searchRegex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive)
        calculateMatches(in: fullAttributedString)
    }

    func highlightNextMatch(in fullAttributedString: NSMutableAttributedString, after afterRange: NSRange?) {
        guard !matchRanges.isEmpty else { return }

        let lastSelectedMatchIndex = selectedMatchIndex

        if selectedMatchIndex == nil, let afterRange, afterRange.location != NSNotFound {
            // find the first index AFTER the afterRangeValue param. This allows us to start selection highlights in the middle of the matches.
            for (i, matchRange) in matchRanges.enumerated() {
                if matchRange.location >= afterRange.location {
                    selectedMatchIndex = i
                    break
                }
            }
            if selectedMatchIndex == nil { selectedMatchIndex = 0 }
        } else if selectedMatchIndex == nil || selectedMatchIndex == matchRanges.count - 1 {
            selectedMatchIndex = 0
        } else {
            selectedMatchIndex! += 1
        }

        updateMatchHighlights(in: fullAttributedString, lastSelectedMatchIndex: lastSelectedMatchIndex)
    }

    func highlightPreviousMatch(in fullAttributedString: NSMutableAttributedString) {
        guard !matchRanges.isEmpty else { return }

        let lastSelectedMatchIndex = selectedMatchIndex
        
        // Decrement index
        if selectedMatchIndex == nil || selectedMatchIndex == 0 {
            selectedMatchIndex = matchRanges.count - 1
        } else {
            selectedMatchIndex! -= 1
        }

        updateMatchHighlights(in: fullAttributedString, lastSelectedMatchIndex: lastSelectedMatchIndex)
    }

    func replaceSingleMatch(in fullAttributedString: NSMutableAttributedString, with replaceText: String, textView: UITextView) {
        guard let currentSelectedMatchRange = selectedMatchRange else { return }

        // add replace range to array
        let newReplaceRange = NSRange(location: currentSelectedMatchRange.location, length: replaceText.count)
        replacedRanges.append(newReplaceRange)

        // get currently selected match text range
        if let startPos = textView.position(from: textView.beginningOfDocument, offset: currentSelectedMatchRange.location),
           let endPos = textView.position(from: startPos, offset: currentSelectedMatchRange.length),
           let selectedMatchTextRange = textView.textRange(from: startPos, to: endPos) {
            // replace text in textview
            textView.replace(selectedMatchTextRange, withText: replaceText)
        }

        // update replace range with new attributes
        if canEvaluateAttributedString(fullAttributedString, againstRange: newReplaceRange) {
            fullAttributedString.beginEditing()
            resetKeys(for: fullAttributedString, range: newReplaceRange)
            fullAttributedString.addAttributes(replacedMatchAttributes, range: newReplaceRange)
            fullAttributedString.endEditing()
        }

        // copy new text view text to keep it in sync
        self.fullAttributedString = textView.attributedText
        
        // reset matches
        matchRanges.removeAll()
        self.selectedMatchIndex = nil

        // recalculate matches and select the first one
        calculateMatches(in: fullAttributedString)
        highlightNextMatch(in: fullAttributedString, after: newReplaceRange)
    }

    func replaceAllMatches(in fullAttributedString: NSMutableAttributedString, with replaceText: String, textView: UITextView) {
        guard let searchText else { return }

        let lengthDelta = replaceText.count - searchText.count
        
        // copy so we aren't removing objects while enumerating an array
        let matchesCopy = Array(matchRanges)

        for (i, matchRange) in matchesCopy.enumerated() {
            // both match and replace ranges need to be adjusted for the text length differences for each iteration. Otherwise ranges are thrown off.
            let offsetMatchRange = NSRange(location: matchRange.location + (lengthDelta * i), length: searchText.count)
            let newReplaceRange = NSRange(location: matchRange.location + (lengthDelta * i), length: replaceText.count)

            // add replace range to array
            replacedRanges.append(newReplaceRange)

            // get currently selected match text range
            if let startPos = textView.position(from: textView.beginningOfDocument, offset: offsetMatchRange.location),
               let endPos = textView.position(from: startPos, offset: offsetMatchRange.length),
               let matchTextRange = textView.textRange(from: startPos, to: endPos) {
                // replace text in textview
                textView.replace(matchTextRange, withText: replaceText)
            }

            // remove first match to keep in sync with remaining matches in text view.
            if !matchRanges.isEmpty {
                matchRanges.removeFirst()
            }

            // update replace range with new attributes
            if canEvaluateAttributedString(fullAttributedString, againstRange: newReplaceRange) {
                fullAttributedString.beginEditing()
                resetKeys(for: fullAttributedString, range: newReplaceRange)
                fullAttributedString.addAttributes(replacedMatchAttributes, range: newReplaceRange)
                fullAttributedString.endEditing()
            }

            // copy new text view text to keep it in sync
            self.fullAttributedString = textView.attributedText
        }

        // reset selected match index
        selectedMatchIndex = nil
    }

    func endMatchSession(with fullAttributedString: NSMutableAttributedString) {
        selectedMatchIndex = nil
        searchText = nil
        searchRegex = nil
        self.fullAttributedString = nil

        matchRanges.removeAll()
        replacedRanges.removeAll()

        fullAttributedString.beginEditing()
        let allRange = NSRange(location: 0, length: fullAttributedString.length)
        resetKeys(for: fullAttributedString, range: allRange)
        fullAttributedString.endEditing()
    }

    // MARK: - Private

    private func calculateMatches(in fullAttributedString: NSMutableAttributedString) {
        self.fullAttributedString = fullAttributedString

        fullAttributedString.beginEditing()
        var newMatchRanges: [NSRange] = []
        searchRegex?.enumerateMatches(in: fullAttributedString.string, range: NSRange(location: 0, length: fullAttributedString.length)) { result, _, _ in
            guard let result else { return }
            let match = result.range(at: 0)
            if match.location != NSNotFound {
                self.resetKeys(for: fullAttributedString, range: match)
                fullAttributedString.addAttributes(self.matchAttributes, range: match)
                newMatchRanges.append(match)
            }
        }
        fullAttributedString.endEditing()
        matchRanges = newMatchRanges
    }

    private func updateMatchHighlights(in fullAttributedString: NSMutableAttributedString, lastSelectedMatchIndex: Int?) {
        fullAttributedString.beginEditing()

        // Pull next range and color as selected
        if let selectedMatchIndex {
            let nextMatchRange = matchRanges[selectedMatchIndex]
            if canEvaluateAttributedString(fullAttributedString, againstRange: nextMatchRange) {
                resetKeys(for: fullAttributedString, range: nextMatchRange)
                fullAttributedString.addAttributes(selectedMatchAttributes, range: nextMatchRange)
            }
        }

        // Color last selected match as regular
        if let lastSelectedMatchIndex, lastSelectedMatchIndex < matchRanges.count {
            let lastSelectedMatchRange = matchRanges[lastSelectedMatchIndex]
            if canEvaluateAttributedString(fullAttributedString, againstRange: lastSelectedMatchRange) {
                resetKeys(for: fullAttributedString, range: lastSelectedMatchRange)
                fullAttributedString.addAttributes(matchAttributes, range: lastSelectedMatchRange)
            }
        }

        fullAttributedString.endEditing()
    }

    private func resetKeys(for attributedString: NSMutableAttributedString, range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.removeAttribute(.foregroundColor, range: range)
        attributedString.removeAttribute(.backgroundColor, range: range)
        attributedString.removeAttribute(.wmfSourceEditorMatch, range: range)
        attributedString.removeAttribute(.wmfSourceEditorSelectedMatch, range: range)
        attributedString.removeAttribute(.wmfSourceEditorReplacedMatch, range: range)
    }
}
