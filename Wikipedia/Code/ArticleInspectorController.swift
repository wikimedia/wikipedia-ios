import Foundation
import CocoaLumberjackSwift
import SwiftSoup
import NaturalLanguage

enum ArticleInspectorError: Error {
    case missingPCSElement
    case missingSections
    case missingSentencesForParagraph
}

@available(iOS 13.0, *)
class ArticleInspectorController {
    
    private let articleURL: URL
    private let fetcher = ArticleInspectorFetcher()
    
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
        var wikiWhoResponse: WikiWhoResponse?
        
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
                wikiWhoResponse = response
            case .failure(let error):
                DDLogError(error)
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let articleHtml = articleHtml,
                  let wikiWhoResponse = wikiWhoResponse {
               
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
        
        //TODO: loop through separated models and return combined models
        return []
    }
}

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
    
    /// Takes soup element object and extracts any sections, paragraphs, and sentences. Each sentence structure will contain both the raw sentence (without html tags) and the html sentence (with html tags). Sections can also contain sections, so this method is recusive.
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
            } catch (let error) {
                DDLogDebug(error)
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
            throw ArticleInspectorError.missingSections
        }
        
        return sections
    }
    
    
    /// Converts a paragraph of sentences into an ArticleInspector Paragraph element, containing IndividualSentence sentences.
    /// - Parameter html: String of paragraph html content, without <p> tags. Can contain html tags within, but not necessary.
    /// - Throws: If there are no sentences extracted, indicating a processing error
    /// - Returns: ArticleInspector Paragraph element
    func paragraphFromHtml(_ html: String) throws -> ArticleInspector.Paragraph<ArticleInspector.IndividualSentence> {
        
        let tags = html.htmlTags()
        let rawText = html.removingHtmlTags(tags)
        let rawSentences = rawText.splittingIntoSentences()
        let individualSentences = individualSentencesFromRawSentences(rawSentences, htmlTags: tags)
        
        guard !individualSentences.isEmpty else {
            throw ArticleInspectorError.missingSentencesForParagraph
        }
        
        return ArticleInspector.Paragraph(sentences: individualSentences)
    }
    
    /// Converts an array un-tagged sentences into ArticleInspector.IndividualSentence elements, which contain untagged sentence and tagged sentence.
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
}

//MARK: Internal hooks for Unit Tests

#if TEST

@available(iOS 13.0, *)
extension ArticleInspectorController {
    func testIndividualSectionsFromHtml(_ html: String) throws -> [ArticleInspector.Section<ArticleInspector.IndividualSentence>] {
        return try individualSectionsFromHtml(html)
    }
}
#endif
