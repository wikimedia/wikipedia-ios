import Foundation

public struct WKWikitextUtils {
    
    // MARK: Nested Types
    
    public struct HtmlInfo {
        let textBeforeTargetText: String
        let targetText: String
        let textAfterTargetText: String
        
        public init(textBeforeTargetText: String, targetText: String, textAfterTargetText: String) {
            self.textBeforeTargetText = textBeforeTargetText
            self.targetText = targetText
            self.textAfterTargetText = textAfterTargetText
        }
    }
    
    // MARK: Properties
    
    private static let adjacentWordCount = 6
    private static let adjacentCharacterCount = 200
    
    /// Helper method to detect the range of selected text within a blob of wikitext.
    /// Essentially uses adjacent text next to selected text and seeks out the best range in wikitext, while ignoring wikitext markup.
    /// - Parameters:
    ///   - selectedInfo: Selected Info struct. See `wmf_getSelectedTextEditInfo` in the client app for assistance in pulling this data from a web view.
    ///   - wikitext: Wikitext to search through
    /// - Returns: NSRange of the selected text in wikitext.
    public static func rangeOf(htmlInfo: HtmlInfo, inWikitext wikitext: String) -> NSRange {
        
        guard !htmlInfo.targetText.isEmpty else {
            return NSRange(location: NSNotFound, length: 0)
        }
        
        let htmlWordsBeforeTargetText = lastWordsOfText(text: htmlInfo.textBeforeTargetText, wordCount: adjacentWordCount)
        let htmlWordsAfterTargetText = firstWordsOfText(text: htmlInfo.textAfterTargetText, wordCount: adjacentWordCount)
        
        let regex = looseTargetTextRegex(htmlTargetText: htmlInfo.targetText)
        guard let matches = regex?.matches(in: wikitext, range: NSRange(location: 0, length: wikitext.count)) else {
            return NSRange(location: NSNotFound, length: 0)
        }
        
        var bestScoredMatch: NSTextCheckingResult?
        var bestScore: Int?
        for match in matches {
            let score = scoreForMatch(match: match, wikitext: wikitext, htmlWordsBeforeTargetText: htmlWordsBeforeTargetText, htmlWordsAfterTargetText: htmlWordsAfterTargetText)
            if score > (bestScore ?? 0) {
                bestScore = score
                bestScoredMatch = match
            }
        }
        
        return bestScoredMatch?.range ?? NSRange(location: NSNotFound, length: 0)
    }
    
    private static func lastWordsOfText(text: String, wordCount: Int) -> [String] {
        return text.split(separator: " ").suffix(wordCount).map {String($0)}
    }
    
    private static func firstWordsOfText(text: String, wordCount: Int) -> [String] {
        return text.split(separator: " ").prefix(wordCount).map {String($0)}
    }
    
    private static func looseTargetTextRegex(htmlTargetText: String) -> NSRegularExpression? {
        
        // Regex pattern is built up here
        
        // We replace all spaces in the htmlTargetText with additional regex that allows for square brackets, templates, html tags, etc.
        let spaceRegexPattern = "\\s+"
        let spaceReplaceRegexPattern = "(?:(?:\\[\\[[^\\]\\|]+\\|)|\\{\\{[^\\}]*\\}\\}|<[^>]*>|\\W)+"
        let spaceRegex = try? NSRegularExpression(pattern: spaceRegexPattern)
        var looseRegexPattern = htmlTargetText
        if let matches = spaceRegex?.matches(in: htmlTargetText, range: NSRange(location: 0, length: htmlTargetText.count)) {
            for match in matches.reversed() {
                looseRegexPattern = (looseRegexPattern as NSString).replacingCharacters(in: match.range, with: spaceReplaceRegexPattern)
            }
        }
        
        return try? NSRegularExpression(pattern: looseRegexPattern)
    }
    
    private static func scoreForMatch(match: NSTextCheckingResult, wikitext: String, htmlWordsBeforeTargetText: [String], htmlWordsAfterTargetText: [String]) -> Int {
        let wikitextRangeBeforeMatchLocation = max(0, match.range.location - adjacentCharacterCount)
        guard let wikitextRangeBeforeMatch = Range(NSRange(location: wikitextRangeBeforeMatchLocation, length: match.range.location - wikitextRangeBeforeMatchLocation), in: wikitext) else {
            return 0
        }
        
        let wikitextBeforeMatch = String(wikitext[wikitextRangeBeforeMatch]).wordsOnly()
        let wikitextWordsBeforeMatch = lastWordsOfText(text: wikitextBeforeMatch, wordCount: adjacentWordCount)
        
        let wikitextRangeAfterMatchLocation = match.range.location + match.range.length
        guard let wikitextRangeAfterMatch = Range(NSRange(location: wikitextRangeAfterMatchLocation, length: min(adjacentCharacterCount, wikitext.count - wikitextRangeAfterMatchLocation)), in: wikitext) else {
            return 0
        }
        
        let wikitextAfterMatch = String(wikitext[wikitextRangeAfterMatch]).wordsOnly()
        let wikitextWordsAfterMatch = firstWordsOfText(text: wikitextAfterMatch, wordCount: adjacentWordCount)
        
        let wordsBeforeScore = calculateScore(htmlWords: htmlWordsBeforeTargetText.reversed(), wikitextWords: wikitextWordsBeforeMatch.reversed())
        let wordsAfterScore = calculateScore(htmlWords: htmlWordsAfterTargetText, wikitextWords: wikitextWordsAfterMatch)
        
        return wordsBeforeScore + wordsAfterScore
    }
    
    private static func calculateScore(htmlWords: [String], wikitextWords: [String]) -> Int {
        
        var score: Int = 0
        
        for (htmlIndex, htmlWord) in htmlWords.enumerated() {
            let indexInWikitextWords = wikitextWords.firstIndex(of: htmlWord)
            
            var wordScore: Int
            if let indexInWikitextWords {
                let distance = indexInWikitextWords - htmlIndex
                wordScore = wikitextWords.count - htmlIndex - distance
            } else {
                wordScore = 0
            }
            
            score += wordScore
        }
        
        return score
    }
    
}

fileprivate extension String {
    /// Replaces parenthesis and characters within with empty string
    /// Replaces templates and characters within with empty string
    /// Replaces any non-word character with empty space
    /// Trims whitespace off final output
    func wordsOnly() -> String {
        let parenthesisRegexPattern = "\\(.*?\\)"
        let templateRegexPattern = "{{.*}}"
        let nonWordRegexPattern = "\\W+"
        
        var finalText = self
        do {
            finalText = try NSRegularExpression(pattern: parenthesisRegexPattern).stringByReplacingMatches(in: self, range: NSRange(location: 0, length: self.count), withTemplate: "")
            finalText = try NSRegularExpression(pattern: templateRegexPattern).stringByReplacingMatches(in: finalText, range: NSRange(location: 0, length: finalText.count), withTemplate: "")
            finalText = try NSRegularExpression(pattern: nonWordRegexPattern).stringByReplacingMatches(in: finalText, range: NSRange(location: 0, length: finalText.count), withTemplate: " ")
            return finalText.trimmingCharacters(in: .whitespaces)
        } catch {
            return finalText.trimmingCharacters(in: .whitespaces)
        }
    }
}
