import Foundation

public struct WKWikitextUtils {
    
    // MARK: Seek range of html text in wikitext
    
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
            
            if var bestScore,
               score > bestScore {
                bestScore = score
                bestScoredMatch = match
            } else if bestScoredMatch == nil {
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
        let wikitextRangeBeforeMatch = NSRange(location: wikitextRangeBeforeMatchLocation, length: match.range.location - wikitextRangeBeforeMatchLocation)
        
        let wikitextBeforeMatch = (wikitext as NSString).substring(with: wikitextRangeBeforeMatch).wordsOnly()
        let wikitextWordsBeforeMatch = lastWordsOfText(text: wikitextBeforeMatch, wordCount: adjacentWordCount)
        
        let wikitextRangeAfterMatchLocation = match.range.location + match.range.length
        let wikitextRangeAfterMatch = NSRange(location: wikitextRangeAfterMatchLocation, length: min(adjacentCharacterCount, wikitext.count - wikitextRangeAfterMatchLocation))
        
        let wikitextAfterMatch = (wikitext as NSString).substring(with: wikitextRangeAfterMatch).wordsOnly()
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
    
    // MARK: - Insert Image Wikitext into Article Wikitext After Templates
    
    private class MarkupInfo {
        
        let openString: String
        let closeString: String
        var openStartIndexes: [String.Index] = []
        
        internal init(openString: String, closeString: String, openStartIndexes: [String.Index] = []) {
            self.openString = openString
            self.closeString = closeString
            self.openStartIndexes = openStartIndexes
        }
    }
    
    public enum ParsingError: Error {
        case closingTemplateMarkupBeforeOpeningMarkup
    }

    public static func insertWikitextintoArticle(imageWikitext: String, caption: String, altText: String, into articleWikitext: String, language: String?) throws -> String {
        let infoboxMatch = getInfoboxMatch(wikitext: articleWikitext)
        var wikitextWithImage: String?
        // if we get the specified infoboxes and the language is en, we try to place in the infobox
        if infoboxMatch != nil && language == "en" {
             wikitextWithImage = try? attempInsertImageWikitextIntoArticleWikitextInfobox(imageWikitext: imageWikitext, caption: caption, altText: caption,into: articleWikitext)

        } else {
            wikitextWithImage = try? insertImageWikitextIntoArticleWikitextAfterTemplates(imageWikitext: imageWikitext, into: articleWikitext)

        }
        return wikitextWithImage ?? String()

    }

    private static let infoboxVarsEnWiki: InfoboxVarsCollection =
    InfoboxVarsCollection(
        regex: "infobox|(?:(?:automatic[ |_])?taxobox)|chembox|drugbox|speciesbox",
        imageKey: "image",
        captionKey: "caption",
        altTextKey: "alt",
        possibleNameParamNames: ["name", "official_name", "species", "taxon", "drug_name", "image"],
        infoboxes: [
            InfoboxVars(infoboxType: "taxobox", imageKey: "image", captionKey: "image_caption", altTextKey: "image_alt"),
            InfoboxVars(infoboxType: "chembox", imageKey: "ImageFile", captionKey: "ImageCaption", altTextKey: "ImageAlt"),
            InfoboxVars(infoboxType: "speciesbox", imageKey: "image", captionKey: "image_caption", altTextKey: "image_alt"),
            InfoboxVars(infoboxType: "infobox.*place", imageKey: "image_skyline", captionKey: "image_caption", altTextKey: "image_alt"),
            InfoboxVars(infoboxType: "infobox.*settlement", imageKey: "image_skyline", captionKey: "image_caption", altTextKey: "image_alt")
        ]
     )

    private static func getInfoboxMatch(wikitext: String) -> NSRange? {
        let infoboxTypesRegex = infoboxVarsEnWiki.regex // "infobox|(?:(?:automatic[ |_])?taxobox)|chembox|drugbox|speciesbox"
            let pattern = "\\{\\{\\s*(\(infoboxTypesRegex))[^\\}]*\\}\\}"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let range = NSRange(location: 0, length: wikitext.utf16.count)
            if let match = regex.firstMatch(in: wikitext, options: [], range: range) {
                print("Match found")
                return match.range
            } else {
                print("No match found")
            }
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
        }
        return nil
    }

    public static func attempInsertImageWikitextIntoArticleWikitextInfobox(imageWikitext: String, caption: String, altText: String, into articleWikitext: String) throws -> String {

        var articleWikitext = articleWikitext

        guard let infoboxMatch = getInfoboxMatch(wikitext: articleWikitext) else {
            // dry it
            articleWikitext = try! insertImageWikitextIntoArticleWikitextAfterTemplates(imageWikitext: imageWikitext, into: articleWikitext)
            return articleWikitext
        }
            let infoboxStartIndex = infoboxMatch.lowerBound
            let infoboxEndIndex = infoboxMatch.upperBound
        let imageParamName = infoboxVarsEnWiki.imageKey

        let haveNameParam = findNameParamInTemplate(infoboxVarsEnWiki.possibleNameParamNames, wikitext: articleWikitext, startIndex: infoboxStartIndex, endIndex: infoboxEndIndex).0 != -1

            if haveNameParam {
                let match = try? NSRegularExpression(pattern: "\\|\\s*\(imageParamName)\\s*=([^|]*)(\\|)")
                let firstMatch = match?.firstMatch(in: articleWikitext, options: [], range: NSRange(infoboxStartIndex..<articleWikitext.utf16.count))
                let group1Range = firstMatch?.range(at: 1)
                let group2Range = firstMatch?.range(at: 2)

                if let group1Range = group1Range, let group2Range = group2Range, group2Range.lowerBound < infoboxEndIndex {
                    var insertPos = group2Range.lowerBound
                    let valueStr = (articleWikitext as NSString).substring(with: group1Range)

                    if valueStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if valueStr.contains("\n") {
                            insertPos = group1Range.lowerBound + valueStr.distance(from: valueStr.startIndex, to: valueStr.firstIndex(of: "\n")!)
                        }
                        if let insertIndex = articleWikitext.index(articleWikitext.startIndex, offsetBy: insertPos, limitedBy: articleWikitext.endIndex) {
                            articleWikitext = articleWikitext[..<insertIndex] + " " + imageWikitext + articleWikitext[insertIndex...]

                        }
                    }
                } else {
                    let paramInsertPosandSpacing = findNameParamInTemplate(infoboxVarsEnWiki.possibleNameParamNames, wikitext: articleWikitext, startIndex: infoboxStartIndex, endIndex: infoboxEndIndex)
                    if paramInsertPosandSpacing.0 > 0 {

                        let insertText = "|\(paramInsertPosandSpacing.1)\(imageParamName) = \(imageWikitext)\n"
                        if let insertIndex = articleWikitext.index(articleWikitext.startIndex, offsetBy: paramInsertPosandSpacing.0, limitedBy: articleWikitext.endIndex) {
                            articleWikitext = articleWikitext[..<insertIndex] + insertText + articleWikitext[insertIndex...]

                        }
                    }
                }

                // repeat for for image caption and alt text
            }

        print("ARTICLE WIKITEXT =================>>>>>>>>>>>>>>>>>>>> \(articleWikitext)")
        return articleWikitext
    }

    static func findNameParamInTemplate(_ possibleNameParamNames: [String], wikitext: String, startIndex: Int, endIndex: Int) -> (Int, String) {
        var paramInsertPos = -1
        var paramNameSpaceConvention = ""

        for nameParam in possibleNameParamNames {
            let regex = try! NSRegularExpression(pattern: "\\|(\\s*)\(nameParam)\\s*=([^|]*)(\\|)")
            if let match = regex.firstMatch(in: wikitext, options: [], range: NSRange(startIndex..<wikitext.utf16.count)) {
                let group1Range = match.range(at: 1)
                let group3Range = match.range(at: 3)
                if group3Range.lowerBound < endIndex {
                    paramInsertPos = group3Range.lowerBound
                    paramNameSpaceConvention = (wikitext as NSString).substring(with: group1Range)
                    break
                }
            }
        }
        return (paramInsertPos, paramNameSpaceConvention)
    }

    /// Inserts image wikitext into article wikitext, after all initial templates.
    /// - Parameters:
    ///   - imageWikitext: image wikitext, e.g. `[[File: Cat.jpg | thumb | 220x124px | right | alt=Cat alt text | Cat caption text]]`
    ///   - articleWikitext: article wikitext
    /// - Returns: Article wikitext, with image wikitext inserted.
    public static func insertImageWikitextIntoArticleWikitextAfterTemplates(imageWikitext: String, into articleWikitext: String) throws -> String {

        guard !imageWikitext.isEmpty else {
            return articleWikitext
        }
        
        let skipMarkupInfos = [
            MarkupInfo(openString: "{{", closeString: "}}"),
            MarkupInfo(openString: "<!--", closeString: "-->")
        ]
        
        var skipMarkupRanges: [Range<String.Index>] = []
        
        for index in articleWikitext.indices {
            
            guard skipMarkupRanges.first(where: { $0.contains(index) }) == nil else {
                continue
            }
            
            guard articleWikitext[index] != "\n" else {
                continue
            }
            
            for markupInfo in skipMarkupInfos {
                
                guard let nextOpenIndex = articleWikitext.index(index, offsetBy: markupInfo.openString.count, limitedBy: articleWikitext.endIndex) else {
                    continue
                }
                
                guard let nextCloseIndex = articleWikitext.index(index, offsetBy: markupInfo.closeString.count, limitedBy: articleWikitext.endIndex) else {
                    continue
                }
                
                let textOpen = articleWikitext[index..<nextOpenIndex]
                let textClose = articleWikitext[index..<nextCloseIndex]
                
                if textOpen == markupInfo.openString {
                    markupInfo.openStartIndexes.append(index)
                } else if textClose == markupInfo.closeString {
                    
                    guard let lastOpenIndex = markupInfo.openStartIndexes.popLast() else {
                        throw ParsingError.closingTemplateMarkupBeforeOpeningMarkup
                    }
                    
                    let range: Range<String.Index> = lastOpenIndex..<nextCloseIndex
                    skipMarkupRanges.append(range)
                }
            }
        }
        
        var finalIndex: String.Index = articleWikitext.startIndex
        for index in articleWikitext.indices {
            
            guard articleWikitext[index] != "\n" else {
                continue
            }
            
            guard skipMarkupRanges.first(where: { $0.contains(index) }) == nil else {
                continue
            }
            
            finalIndex = index
            break
        }
        
        var insertedArticleWikitext = articleWikitext
        var finalImageWikitext = imageWikitext
        if finalIndex != articleWikitext.startIndex {
            let previousIndex = articleWikitext.index(before: finalIndex)
            if articleWikitext[previousIndex] == "\n" {
                finalImageWikitext = finalImageWikitext + "\n"
            } else {
                finalImageWikitext = "\n" + finalImageWikitext + "\n"
            }
            
        }
        insertedArticleWikitext.insert(contentsOf: finalImageWikitext, at: finalIndex)
        return insertedArticleWikitext
    }
}

fileprivate extension String {
    /// Replaces parenthesis and characters within with empty string
    /// Replaces templates and characters within with empty string
    /// Replaces any non-word character with empty space
    /// Trims whitespace off final output
    func wordsOnly() -> String {
        let parenthesisRegexPattern = "\\(.*?\\)"
        let templateRegexPattern = "\\{\\{.*\\}\\}"
        let nonWordRegexPattern = "\\W+"
        
        var finalText = self
        
        if let parenthesisMatches = try? NSRegularExpression(pattern: parenthesisRegexPattern).matches(in: finalText, range: NSRange(location: 0, length: finalText.count)) {
            for match in parenthesisMatches.reversed() {
                finalText = (finalText as NSString).replacingCharacters(in: match.range, with: "")
            }
        }
        
        if let templateMatches = try? NSRegularExpression(pattern: templateRegexPattern).matches(in: finalText, range: NSRange(location: 0, length: finalText.count)) {
            for match in templateMatches.reversed() {
                finalText = (finalText as NSString).replacingCharacters(in: match.range, with: "")
            }
        }
        
        if let nonWordMatches = try? NSRegularExpression(pattern: nonWordRegexPattern).matches(in: finalText, range: NSRange(location: 0, length: finalText.count)) {
            for match in nonWordMatches.reversed() {
                finalText = (finalText as NSString).replacingCharacters(in: match.range, with: " ")
            }
        }
        
        return finalText.trimmingCharacters(in: .whitespaces)
    }
}

private struct InfoboxVars {
    let infoboxType: String
    let imageKey: String
    let captionKey: String
    let altTextKey: String
}

private struct InfoboxVarsCollection {
    let regex: String
    let imageKey: String
    let captionKey: String
    let altTextKey: String
    let possibleNameParamNames: [String]
    let infoboxes: [InfoboxVars]
}
