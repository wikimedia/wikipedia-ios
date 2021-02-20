import Foundation
import CocoaLumberjackSwift
import SwiftSoup
import NaturalLanguage

enum ArticleInspectorError: Error {
    case missingPCSElement
    case missingIndividualSections
    case missingCombinedSections
    case missingIndividualSentencesForParagraph
    case missingCombinedSentencesForParagraph
    case nonMatchingArticleAndWikiWhoSections
    case nonMatchingArticleAndWikiWhoSentences
    case missingWikiWhoRevisionForRevisionID
    case missingWikiWhoEditorForEditorID
    case creatingCombinedSentenceWithoutWikiWhoResponse
}

@available(iOS 13.0, *)
class ArticleInspectorController {
    
    private let articleURL: URL
    private let fetcher = ArticleInspectorFetcher()
    private var wikiWhoResponse: WikiWhoResponse!
    
    init(articleURL: URL) {
        self.articleURL = articleURL
    }
    
    var isEnabled: Bool {
        
        //TODO: replace with experiment checking, site=en & !rtl logic
        return false
    }
    
    func articleContentFinishedLoading(messagingController: ArticleWebMessagingController) {
        
        guard isEnabled else {
            return
        }
        
        guard let title = articleURL.wmf_title?.denormalizedPageTitle else {
            DDLogError("Failure constructing article title.")
            return
        }
        
        let group = DispatchGroup()
        
        var articleHtml: String?
        
        group.enter()
        messagingController.htmlContent { (response) in
            
            defer {
                group.leave()
            }
            
            guard let response = response else {
                return
            }
            
            articleHtml = response
        }
        
        group.enter()
        fetcher.fetchWikiWho(articleTitle: title) { (result) in

            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                self.wikiWhoResponse = response
            case .failure(let error):
                DDLogError(error)
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            if let articleHtml = articleHtml,
               let wikiWhoResponse = self.wikiWhoResponse {
               
                do {
                    try self.processContent(articleHtml: articleHtml, wikiWhoResponse: wikiWhoResponse)
                } catch (let error) {
                    DDLogError(error)
                }
                
            } else {
                DDLogError("Failure fetching articleHtml or wikiWhoResponse")
            }
        }
        
    }
    
    /// // Transforms article html, annotated WikiWho html and associated editor and revision information into combined structs for easier article content sentence highlighting and Article Inspector modal display.
    /// - Parameters:
    ///   - articleHtml: Article content html
    ///   - wikiWhoResponse: Decoded WikiWho data from labs WikiWho endpoint
    func processContent(articleHtml: String, wikiWhoResponse: WikiWhoResponse) throws -> [ArticleInspector.Section<ArticleInspector.CombinedSentence>] {
        
        let articleHtmlSections = try individualSectionsFromHtml(articleHtml)
        let wikiWhoSections = try individualSectionsFromHtml(wikiWhoResponse.extendedHtml)
        
        let combinedSections = try self.combinedSections(articleSections: articleHtmlSections, wikiWhoSections: wikiWhoSections)
        
        //TODO: loop through separated models and return combined models
        return []
    }
}

//MARK: Individual processing

@available(iOS 13.0, *)
private extension ArticleInspectorController {
    
    /// Takes content of a complete html source and breaks it down into sections, paragraphs, and sentences. Each sentence structure will contain both the raw sentence (without html tags) and the html sentence (with html tags).
    /// - Parameter html: String of the complete html content, to be parsed with SwiftSoup
    /// - Throws: If there are no sections returned or html argument is missing a pcs element.
    /// - Returns: Array of ArticleInspector section objects
    func individualSectionsFromHtml(_ html: String) throws -> [ArticleInspector.Section<ArticleInspector.IndividualSentence>] {
        
        let doc: Document = try SwiftSoup.parse(html)
        let maybePCS = try doc.body()?.getElementById("pcs")
        
        guard let pcs = maybePCS else {
            throw ArticleInspectorError.missingPCSElement
        }
        
        let sections = try sectionsFromSoupElement(pcs)
        return sections
    }
    
    /// Takes soup element object and extracts any sections, paragraphs, and sentences. Each sentence structure will contain both the raw sentence (without html tags) and the html sentence (with html tags). Sections can also contain sections, so this method is recursive.
    /// - Parameter element: SwiftSoup element object
    /// - Throws: If there are no sections returned
    /// - Returns: Array of ArticleInspector section objects
    func sectionsFromSoupElement(_ element: Element) throws -> [ArticleInspector.Section<ArticleInspector.IndividualSentence>] {
        let soupSections = element.children().filter { $0.tagName() == "section" }
        var sections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>] = []
        for soupSection in soupSections {
            
            let childSections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>]
            do {
                childSections = try sectionsFromSoupElement(soupSection)
            } catch {
                //Not unusual for a section to not have child sections
                childSections = []
            }
            
            let soupParagraphs = soupSection.children().filter { $0.tagName() == "p" }
            let paragraphs = soupParagraphs.compactMap { (soupParagraph) -> ArticleInspector.Paragraph<ArticleInspector.IndividualSentence>? in
                do {
                    let html = try soupParagraph.html()
                    return try paragraphFromHtml(html)
                } catch (let error) {
                    DDLogDebug(error)
                    return nil
                }
            }
            
            let sectionTitle: String?
            do {
                sectionTitle = try soupSection.select("h2, h3, h4, h5, h6, h7").first()?.text()
            } catch (let error) {
                sectionTitle = nil
                DDLogDebug(error)
            }
            
            let sectionIdentifier: Int
            do {
                let stringSectionIdentifier = try soupSection.attr("data-mw-section-id")
                guard let intSectionIdentifier = Int(stringSectionIdentifier) else {
                    DDLogDebug("Unable to extract section identifier")
                    continue
                }
                sectionIdentifier = intSectionIdentifier
            } catch (let error) {
                DDLogDebug(error)
                continue
            }
            
            let section = ArticleInspector.Section(title: sectionTitle, identifier: sectionIdentifier, sections: childSections, paragraphs: paragraphs)
            
            sections.append(section)
        }
        
        guard sections.count > 0 else {
            throw ArticleInspectorError.missingIndividualSections
        }
        
        return sections
    }
    
    
    /// Method that converts a paragraph of sentences into an ArticleInspector Paragraph element, containing IndividualSentence sentences.
    /// - Parameter html: String of paragraph html content, without <p> tags. Can contain html tags within, but not necessary.
    /// - Throws: If there are no sentences extracted, indicating a processing error
    /// - Returns: ArticleInspector Paragraph element
    func paragraphFromHtml(_ html: String) throws -> ArticleInspector.Paragraph<ArticleInspector.IndividualSentence> {
        
        let tags = html.htmlTags()
        let rawText = html.removingHtmlTags(tags)
        let rawSentences = rawText.splittingIntoSentences()
        let individualSentences = individualSentencesFromRawSentences(rawSentences, htmlTags: tags)
        
        guard (!individualSentences.isEmpty || html.isEmpty) else {
            throw ArticleInspectorError.missingIndividualSentencesForParagraph
        }
        
        return ArticleInspector.Paragraph(sentences: individualSentences)
    }
    
    /// Method that converts an array un-tagged sentences into ArticleInspector.IndividualSentence elements, which contain untagged sentence and tagged sentence.
    /// - Parameters:
    ///   - rawSentences: Array of sentence strings, without html tags
    ///   - htmlTags: Array of html tag elements to be interspersed throughout the raw sentences
    /// - Returns: Array of ArticleInspector.IndividualSentence, containing mapped raw sentences to their html-tagged sentence counterparts.
    func individualSentencesFromRawSentences(_ rawSentences: [String], htmlTags: [ArticleInspector.HtmlTag]) -> [ArticleInspector.IndividualSentence] {
        var individualSentences: [ArticleInspector.IndividualSentence] = []
        var htmlSentences: [String] = []
        
        for rawSentence in rawSentences {
            var offset = 0
            for htmlSentence in htmlSentences {
                offset += htmlSentence.count
            }
            
            let htmlSentence = rawSentence.addingHtml(tags: htmlTags, offset: offset)
            let individualSentence = ArticleInspector.IndividualSentence(htmlText: htmlSentence, rawText: rawSentence)
            individualSentences.append(individualSentence)
            htmlSentences.append(htmlSentence)
        }
        
        return individualSentences
    }
}

//MARK: Combined Processing

@available(iOS 13.0, *)
private extension ArticleInspectorController {
    
    /// Correlates sections (with individual sentences) processed from article content and wikiwho html via their matching rawText sentences. Puts associated information together into sections of combined sentences. Sections can also contain sections, so this method is recursive.
    /// - Parameters:
    ///   - articleSections: Sections of individual sentences parsed from the article content html
    ///   - wikiWhoSections: Sections of individual sentences parsed from the WikiWho content html
    /// - Throws: Error if parameters are empty or resulting combined sections are empty
    /// - Returns: Array of sections with combined sentences
    private func combinedSections(articleSections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>], wikiWhoSections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>]) throws -> [ArticleInspector.Section<ArticleInspector.CombinedSentence>] {
        guard !articleSections.isEmpty,
              !wikiWhoSections.isEmpty else {
            throw ArticleInspectorError.missingIndividualSections
        }
        
        let zippedSections = zip(wikiWhoSections, articleSections)
        let finalSections = zippedSections.compactMap { (zippedSection) -> ArticleInspector.Section<ArticleInspector.CombinedSentence>? in
            let wikiWhoSection = zippedSection.0
            let articleSection = zippedSection.1
            
            do {
                return try combinedSection(wikiWhoSection: wikiWhoSection, articleSection: articleSection)
            } catch {
                DDLogDebug(error)
                return nil
            }
            
        }
        
        guard finalSections.count > 0 else {
            throw ArticleInspectorError.missingCombinedSections
        }
        
        return finalSections
    }
    
    
    /// Correlates section (with individual sentences) processed from article content and wikiwho html via their matching rawText sentences. Puts associated information together into section of combined sentences.
    /// - Parameters:
    ///   - wikiWhoSection: Single section of individual sentences parsed from the WikiWho html
    ///   - articleSection: Single section of individual sentences parsed from the article content html
    /// - Throws: Throws if WikiWho section and article section do not have matching titles or identifiers
    /// - Returns: Section with combined sentences
    private func combinedSection(wikiWhoSection: ArticleInspector.Section<ArticleInspector.IndividualSentence>, articleSection: ArticleInspector.Section<ArticleInspector.IndividualSentence>) throws -> ArticleInspector.Section<ArticleInspector.CombinedSentence> {
        
        guard wikiWhoSection.title == articleSection.title,
              wikiWhoSection.identifier == articleSection.identifier else {
            throw ArticleInspectorError.nonMatchingArticleAndWikiWhoSections
        }
        
        let childSections: [ArticleInspector.Section<ArticleInspector.CombinedSentence>]
        do {
            childSections = try combinedSections(articleSections: articleSection.sections, wikiWhoSections: wikiWhoSection.sections)
        } catch {
            //Not unusual for a section to not have child sections
            childSections = []
        }
        
        let zippedParagraphs = zip(wikiWhoSection.paragraphs, articleSection.paragraphs)
        let combinedParagraphs = zippedParagraphs.compactMap { (zippedParagraph) -> ArticleInspector.Paragraph<ArticleInspector.CombinedSentence>? in
            let wikiWhoParagraph = zippedParagraph.0
            let articleParagraph = zippedParagraph.1
            
            do {
                return try combinedParagraph(wikiWhoParagraph: wikiWhoParagraph, articleParagraph: articleParagraph)
            } catch {
                DDLogDebug(error)
                return nil
            }
        }
        
        let finalSection = ArticleInspector.Section<ArticleInspector.CombinedSentence>(title: wikiWhoSection.title, identifier: wikiWhoSection.identifier, sections: childSections, paragraphs: combinedParagraphs)
        return finalSection
    }
    
    
    /// Correlates paragraph (with individual sentences) processed from article content and wikiwho html via their matching rawText sentences. Puts associated information together into paragraph of combined sentences.
    /// - Parameters:
    ///   - wikiWhoParagraph: Single paragraph of individual sentences parsed from the WikiWho html
    ///   - articleParagraph: Single paragraph of individual sentences parsed from the article content html
    /// - Throws: If there are no resulting combined sentences in paragraph
    /// - Returns: Paragraph with combined sentences
    private func combinedParagraph(wikiWhoParagraph: ArticleInspector.Paragraph<ArticleInspector.IndividualSentence>, articleParagraph: ArticleInspector.Paragraph<ArticleInspector.IndividualSentence>) throws -> ArticleInspector.Paragraph<ArticleInspector.CombinedSentence> {
        
        let zippedSentences = zip(wikiWhoParagraph.sentences, articleParagraph.sentences)
        let combinedSentences = zippedSentences.compactMap { (zippedSentence) -> ArticleInspector.CombinedSentence? in
            let wikiWhoSentence = zippedSentence.0
            let articleSentence = zippedSentence.1
            
            do {
                return try combinedSentence(wikiWhoSentence: wikiWhoSentence, articleSentence: articleSentence)
            } catch {
                DDLogDebug(error)
                return nil
            }
            
        }
        
        guard combinedSentences.count > 0 else {
            throw ArticleInspectorError.missingCombinedSentencesForParagraph
        }
        
        return ArticleInspector.Paragraph<ArticleInspector.CombinedSentence>(sentences: combinedSentences)
    }
    
    /// Combines single sentence from a WikiWho html response with a single sentence from article html. Expects the rawText of each to match.
    /// - Parameters:
    ///   - wikiWhoSentence: Single sentence from a WikiWho html response
    ///   - articleSentence: Single sentence from article html
    /// - Throws: If sentence rawTexts do not match, or failure to extract annotated data from WikiWhoResponse
    /// - Returns: Combined sentence
    private func combinedSentence(wikiWhoSentence: ArticleInspector.IndividualSentence, articleSentence: ArticleInspector.IndividualSentence) throws -> ArticleInspector.CombinedSentence {
        guard wikiWhoSentence.rawText == articleSentence.rawText else {
            throw ArticleInspectorError.nonMatchingArticleAndWikiWhoSentences
        }
        
        guard let wikiWhoResponse = self.wikiWhoResponse else {
            throw ArticleInspectorError.creatingCombinedSentenceWithoutWikiWhoResponse
        }
        
        let annotatedData = try self.annotatedData(wikiWhoResponse: wikiWhoResponse, wikiWhoSentence: wikiWhoSentence)
        
        return ArticleInspector.CombinedSentence(articleText: articleSentence.htmlText, nativeText: wikiWhoSentence.htmlText, rawText: wikiWhoSentence.rawText, annotatedData: annotatedData)
    }
}

//MARK: AnnotatedData Processing

@available(iOS 13.0, *)
private extension ArticleInspectorController {
    
    
    /// Extracts annotated data (tokens, editors, revisions) for any WikiWho sentence.
    /// - Parameters:
    ///   - wikiWhoResponse: Decoded WikiWhoResponse object from WikiWho endpoint
    ///   - wikiWhoSentence: Parsed individual WikiWho sentence
    /// - Throws: If there's a failure to extract revision or editor data
    /// - Returns: Array of annotated data for the WikiWho sentence, each token and it's associated editor and revision.
    func annotatedData(wikiWhoResponse: WikiWhoResponse, wikiWhoSentence: ArticleInspector.IndividualSentence) throws -> [ArticleInspector.AnnotatedData] {
        
        let tokenIDs = wikiWhoSentence.htmlText.tokenIDs()
        let tokensPerRevision = self.tokensPerRevision(wikiWhoResponse: wikiWhoResponse, tokenIDs: tokenIDs)
        
        var annotatedData: [ArticleInspector.AnnotatedData] = []
        for (revisionID, tokens) in tokensPerRevision {
            
            let revisionTuple = try revisionInfo(wikiWhoResponse: wikiWhoResponse, revisionID: revisionID)
            
            let revisionInfo = revisionTuple.0
            let editorID = revisionTuple.1
            
            let editorInfo = try self.editorInfo(wikiWhoResponse: wikiWhoResponse, editorID: editorID)
            
            annotatedData.append(ArticleInspector.AnnotatedData(revisionInfo: revisionInfo, editorInfo: editorInfo, tokens: tokens))
        }
        
        return annotatedData.sorted(by: { $0.revisionInfo.identifier < $1.revisionInfo.identifier })
    }
    
    /// Generates token data from WikiWho response, organized into dictionary keyed by revision ID
    /// - Parameters:
    ///   - wikiWhoResponse: Decoded WikiWho response from endpoint
    ///   - tokenIDs: Set of token integers extracted from WikiWho response extended html
    /// - Returns: Dictionary of tokens, keyed by revision ID
    func tokensPerRevision(wikiWhoResponse: WikiWhoResponse, tokenIDs: Set<Int>) -> [String: [ArticleInspector.AnnotatedData.Token]] {
        
        var result: [String: [ArticleInspector.AnnotatedData.Token]] = [:]
                
        for tokenID in tokenIDs {
            
            //Token IDs extracted from WikiWhoResponse html maps to index of tokens array from WikiWhoResponse
            
            //Note: It seems WikiWho returns one less token than expected. Bailing early to avoid index out of range errors
            if tokenID >= wikiWhoResponse.tokens.count {
                continue
            }
            
            let wikiWhoToken = wikiWhoResponse.tokens[tokenID]
            
            let revisionID = wikiWhoToken.revisionID
            let token = ArticleInspector.AnnotatedData.Token(identifier: tokenID, text: wikiWhoToken.text)
            var tokens = result[String(revisionID)] ?? []
            tokens.append(token)
            result[String(revisionID)] = tokens.sorted(by: { $0.identifier < $1.identifier })
        }
        
        return result
    }
    
    func revisionInfo(wikiWhoResponse: WikiWhoResponse, revisionID: String) throws -> (ArticleInspector.AnnotatedData.RevisionInfo, String) {
        
        guard let wikiWhoRevision = wikiWhoResponse.revisions[revisionID] else {
            throw ArticleInspectorError.missingWikiWhoRevisionForRevisionID
        }
        
        let editorID = wikiWhoRevision.editorID
        let revisionInfo = ArticleInspector.AnnotatedData.RevisionInfo(identifier: wikiWhoRevision.revisionID, dateString: wikiWhoRevision.revisionDateString)
        
        return (revisionInfo, editorID)
    }
    
    func editorInfo(wikiWhoResponse: WikiWhoResponse, editorID: String) throws -> ArticleInspector.AnnotatedData.EditorInfo {
        
        
        let maybeWikiWhoEditor = wikiWhoResponse.editors.first(where: { (wikiWhoEditor) -> Bool in
            wikiWhoEditor.editorID == editorID
        })
        
        guard let wikiWhoEditor = maybeWikiWhoEditor else {
            throw ArticleInspectorError.missingWikiWhoEditorForEditorID
        }
        
        let editorInfo = ArticleInspector.AnnotatedData.EditorInfo(userID: wikiWhoEditor.editorID, username: wikiWhoEditor.editorName, percentage: Double(wikiWhoEditor.editorPercentage))
        return editorInfo
    }
}

//MARK: String helpers

fileprivate extension String {
    
    /// Extracts html tags from any given string
    /// - Returns: Array of HtmlTag elements. An opening tag and a closing tag are considered separate elements.
    func htmlTags() -> [ArticleInspector.HtmlTag] {
        var htmlTags: [ArticleInspector.HtmlTag] = []
        (self as NSString).wmf_enumerateHTMLTags { (tagName, tagAttributes, range) in
            
            let spacedTagAttributes = tagAttributes.count == 0 ? "" : " \(tagAttributes)"
            let tagText = "<\(tagName)\(spacedTagAttributes)>"
            let tag = ArticleInspector.HtmlTag(text: tagText, range: range)
            htmlTags.append(tag)
        }
        
        return htmlTags
    }
    
    /// Returns text interspersed with html tags passed in
    /// - Parameters:
    ///   - tags: Html tags to intersperse in text
    ///   - offset: Offset to apply to tag range processing. Allows for bypassing html tags that do not apply to caller.
    /// - Returns: Text with html tags interspersed.
    func addingHtml(tags: [ArticleInspector.HtmlTag], offset: Int) -> String {
        var text = self
        for tag in tags {
            
            guard tag.range.location >= offset else {
                continue
            }
            
            let newLocation = tag.range.location - offset
            guard newLocation < text.count else {
                continue
            }
            
            text = (text as NSString).replacingCharacters(in: NSRange(location: newLocation, length: 0), with: tag.text)
        }
        
        return text
    }
    
    /// Strips html tags from a string
    /// - Parameter tags: html tags to strip, in the order they appear in the string.
    /// - Returns: String with html tags stripped
    func removingHtmlTags(_ tags: [ArticleInspector.HtmlTag]) -> String {
        
        let reversedTags = tags.reversed()
        var text = self
        for tag in reversedTags {
            text = (text as NSString).replacingCharacters(in: tag.range, with: "")
        }
        
        return text
    }
    
    /// Splits any text into sentences using Apple's Natural Language framework
    /// - Returns: Array of Strings for each detected sentence.
    func splittingIntoSentences() -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = self
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: self.startIndex..<self.endIndex) { (tokenRange, _) -> Bool in
            sentences.append(String(self[tokenRange]))
            return true
        }
        
        return sentences
    }
    
    
    /// Extracts token IDs from a string, assumed to contain html tags with attributes matching "id=token-nnnnn"
    /// - Returns: Set of token identifiers (Ints)
    func tokenIDs() -> Set<Int> {
        
        var result: Set<Int> = []
        
        let pattern = "id=\"token-(\\d+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: self, range:NSMakeRange(0, self.utf16.count))
        for match in matches {
            
            guard match.numberOfRanges > 1 else {
                continue
            }
        
            let matchRange = match.range(at: 1)
            let token = (self as NSString).substring(with: matchRange)

            guard let intToken = Int(token) else {
                DDLogDebug("Failure to cast token to Int")
                continue
            }
            
            result.insert(intToken)
        }
        
        return result
    }
}

//MARK: Internal hooks for Unit Tests

#if TEST

@available(iOS 13.0, *)
extension ArticleInspectorController {
    func testIndividualSectionsFromHtml(_ html: String) throws -> [ArticleInspector.Section<ArticleInspector.IndividualSentence>] {
        return try individualSectionsFromHtml(html)
    }
    
    func testCombinedSections(articleSections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>], wikiWhoSections: [ArticleInspector.Section<ArticleInspector.IndividualSentence>]) throws -> [ArticleInspector.Section<ArticleInspector.CombinedSentence>] {
        return try combinedSections(articleSections: articleSections, wikiWhoSections: wikiWhoSections)
    }
    
    func testSetWikiWhoResponse(_ wikiWhoResponse: WikiWhoResponse) {
        self.wikiWhoResponse = wikiWhoResponse
    }
}
#endif
