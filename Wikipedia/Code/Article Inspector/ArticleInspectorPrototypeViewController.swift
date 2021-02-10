
import UIKit
import SwiftSoup
import NaturalLanguage

//----------

struct ArticleInspectorCombinedSentence {
    let htmlText: String
    let annotatedText: String
    let rawText: String
}

struct ArticleInspectorCombinedParagraph {
    let sentences: [ArticleInspectorCombinedSentence]
}

struct ArticleInspectorCombinedSection {
    let title: String?
    let identifier: Int
    let sections: [ArticleInspectorCombinedSection]
    let paragraphs: [ArticleInspectorCombinedParagraph]
}

//----------

struct ArticleInspectorSection {
    let title: String?
    let identifier: Int
    let sections: [ArticleInspectorSection]
    let paragraphs: [ArticleInspectorParagraph]
}

struct ArticleInspectorParagraph {
    struct HtmlTag {
        let text: String
        let range: NSRange
    }
    struct Sentence {
        let htmlText: String
        let text: String
    }
    let htmlText: String
    let text: String
    let tags: [HtmlTag]
    let sentences: [Sentence]
}

//----------

class ArticleInspectorPrototypeViewController: ViewController {
    
    @IBOutlet weak var testLabel: UILabel!
    var webViewHTML: String? = nil
    var articleTitle: String? = nil
    var webViewSections: [ArticleInspectorSection] = []
    var annotatedSections: [ArticleInspectorSection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        testLabel.text = webViewHTML
        if let articleTitle = articleTitle?.denormalizedPageTitle {
            fetchAnnotatedHTML(title: articleTitle) { (annotatedHTML) in
                guard let annotatedHTML = annotatedHTML else {
                    print("annotatedHTML is nil")
                    return
                }

                self.annotatedSections = self.analyzeHTML(html: annotatedHTML)
                let combinedSections = self.combineWebViewAndAnnotatedSections()
                print(combinedSections)
            }
        }
        
        if let webViewHTML = webViewHTML {
            self.webViewSections = analyzeHTML(html: webViewHTML)
            let combinedSections = self.combineWebViewAndAnnotatedSections()
            print(combinedSections)
        }
    }
    
    func combineWebViewAndAnnotatedSections() -> [ArticleInspectorCombinedSection] {
        guard !annotatedSections.isEmpty,
              !webViewSections.isEmpty else {
            return []
        }
        
        var combinedSections: [ArticleInspectorCombinedSection] = []
        for (index, annotatedSection) in annotatedSections.enumerated() {
            guard let webViewSection = webViewSections[safeIndex: index] else {
                continue
            }
            let combinedSection = getCombinedSection(annotatedSection: annotatedSection, webViewSection: webViewSection)
            combinedSections.append(combinedSection)
        }
        
        return combinedSections
    }
    
    func getCombinedSection(annotatedSection: ArticleInspectorSection, webViewSection: ArticleInspectorSection) -> ArticleInspectorCombinedSection {
        
        var combinedSections: [ArticleInspectorCombinedSection] = []
        for (index, annotatedSection) in annotatedSection.sections.enumerated() {
            guard let webViewSection = webViewSection.sections[safeIndex: index] else {
                continue
            }
            let combinedSection = getCombinedSection(annotatedSection: annotatedSection, webViewSection: webViewSection)
            combinedSections.append(combinedSection)
        }
        
        var combinedParagraphs: [ArticleInspectorCombinedParagraph] = []
        for (index, annotatedParagraph) in annotatedSection.paragraphs.enumerated() {
            guard let webViewParagraph = webViewSection.paragraphs[safeIndex: index] else {
                continue
            }
            
            var combinedSentences: [ArticleInspectorCombinedSentence] = []
            for (sentenceIndex, annotatedSentence) in annotatedParagraph.sentences.enumerated() {
                guard let webViewSentence = webViewParagraph.sentences[safeIndex: sentenceIndex] else {
                    continue
                }
                
                guard annotatedSentence.text == webViewSentence.text else {
                    continue
                }
                
                let combinedSentence = ArticleInspectorCombinedSentence(htmlText: webViewSentence.htmlText, annotatedText: annotatedSentence.htmlText, rawText: annotatedSentence.text)
                combinedSentences.append(combinedSentence)
            }
            
            let combinedParagraph = ArticleInspectorCombinedParagraph(sentences: combinedSentences)
            combinedParagraphs.append(combinedParagraph)
        }
        
        return ArticleInspectorCombinedSection(title: annotatedSection.title, identifier: annotatedSection.identifier, sections: combinedSections, paragraphs: combinedParagraphs)
    }
    
    func analyzeHTML(html: String) -> [ArticleInspectorSection] {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let pcs = try doc.body()?.getElementById("pcs")
            let firstLevelSections = pcs?.children().filter { $0.tagName() == "section" }
            let convertedSections = firstLevelSections?.compactMap{ sectionFromSoupSection(soupSection: $0 ) }
            return convertedSections ?? []
        } catch (let error) {
            print(error)
            return []
        }
    }
    
    func paragraphFromHtml(html: String) -> ArticleInspectorParagraph {
        var htmlTags: [ArticleInspectorParagraph.HtmlTag] = []
        (html as NSString).wmf_enumerateHTMLTags { (tagName, tagAttributes, range) in
            
            let spacedTagAttributes = tagAttributes.count == 0 ? "" : " \(tagAttributes)"
            let htmlTagText = "<\(tagName)\(spacedTagAttributes)>"
            let htmlTag = ArticleInspectorParagraph.HtmlTag(text: htmlTagText, range: range)
            htmlTags.append(htmlTag)
        }
        let reversedTags = htmlTags.reversed()
        var text = html
        for htmlTag in reversedTags {
            text = (text as NSString).replacingCharacters(in: htmlTag.range, with: "")
        }
        
        let rawSentences = sentencesFromParagraphText(text)
        let packagedSentences = htmlSentencesFromRawSentences(rawSentences: rawSentences, htmlTags: htmlTags)
        
        return ArticleInspectorParagraph(htmlText: html, text: text, tags: htmlTags, sentences: packagedSentences)
    }
    
    func htmlSentencesFromRawSentences(rawSentences: [String], htmlTags: [ArticleInspectorParagraph.HtmlTag]) -> [ArticleInspectorParagraph.Sentence] {
        var sentences: [ArticleInspectorParagraph.Sentence] = []
        var offset = 0
        //todo: clean up
        var lastHtmlText: String?
        for rawSentence in rawSentences {
            //note regarding previousHtmlSentence - that may not be the previous one with an annotated token. Might need to pass them all in and loop backwards until we find one.
            //todo ^
            let htmlSentence = htmlFromRawText(text: rawSentence, tags: htmlTags, offset: offset, previousHtmlSentence: lastHtmlText)
            let suffixedSentence = addAnnotationSpanSuffixToSentenceIfNeeded(html: htmlSentence)
            let sentence = ArticleInspectorParagraph.Sentence(htmlText: suffixedSentence, text: rawSentence)
            sentences.append(sentence)
            offset = htmlSentence.count
            lastHtmlText = htmlSentence
        }
        
        return sentences
    }
    
    func sentencesFromParagraphText(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            sentences.append(String(text[tokenRange]))
            return true
        }
        
        return sentences
    }
    
    func htmlFromRawText(text: String, tags: [ArticleInspectorParagraph.HtmlTag], offset: Int, previousHtmlSentence: String?) -> String {
        var html = text
        //todo: audit these < and offset delimiters
        for tag in tags {
            if tag.range.location < offset {
                continue
            }
            let location = tag.range.location - offset
            if location <= html.count {
                html = (html as NSString).replacingCharacters(in: NSRange(location: tag.range.location - offset, length: 0), with: tag.text)
            }
        }
        
        html = addAnnotationSpanPrefixToSentenceIfNeeded(html: html, previousHtmlSentence: previousHtmlSentence)
        
        return html
    }
    
    func needsToAddSpanSuffix(html: String) -> Bool {
        let maybeSpanStart = html.range(of: "<span", options:NSString.CompareOptions.backwards)
        let maybeSpanEnd = html.range(of: "</span>", options:NSString.CompareOptions.backwards)
        
        guard let spanStart = maybeSpanStart else {
            return false
        }
        
        if let spanEnd = maybeSpanEnd {
            return spanStart.lowerBound >= spanEnd.upperBound
        }
        
        return true
    }
    
    func needsToAddSpanPrefix(html: String) -> Bool {

        let maybeSpanStart = html.range(of: "<span")
        let maybeSpanEnd = html.range(of: "</span>")
        
        guard let spanEnd = maybeSpanEnd else {
            return false
        }
        
        if let spanStart = maybeSpanStart {
            return spanEnd.upperBound <= spanStart.lowerBound
        }
        
        return true
    }
    
    func addAnnotationSpanSuffixToSentenceIfNeeded(html: String) -> String {
        
        guard needsToAddSpanSuffix(html: html) else {
            return html
        }
        
        return html + "</span>"
    }
    
    func addAnnotationSpanPrefixToSentenceIfNeeded(html: String, previousHtmlSentence: String?) -> String {
        
        guard let previousHtmlSentence = previousHtmlSentence else {
            return html
        }
        
        guard needsToAddSpanPrefix(html: html) else {
            return html
        }
        
        let pattern = "(<span class=\"editor-token token-editor-\\d*\" id=\"token-\\d*\">)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return html
        }
        
        let result = regex.matches(in: previousHtmlSentence, range:NSMakeRange(0, previousHtmlSentence.utf16.count))
        if let lastMatch = result.last?.range(at: 0) {
            let prefix = (previousHtmlSentence as NSString).substring(with: lastMatch)
            return prefix + html
        }
        
        return html
    }
    
    func sectionFromSoupSection(soupSection: SwiftSoup.Element) -> ArticleInspectorSection? {
        let sections = soupSection.children().filter { $0.tagName() == "section" }
        let convertedSections = sections.compactMap({ (section) -> ArticleInspectorSection? in
            return sectionFromSoupSection(soupSection: section)
        })
        
        let paragraphs = soupSection.children().filter { $0.tagName() == "p" }.compactMap({ (paragraph) -> ArticleInspectorParagraph? in
            do {
                let text = try paragraph.html()
                return paragraphFromHtml(html: text)
            } catch (let error) {
                print(error)
                return nil
            }
        })
        
        do {
            //todo: better section title choosing. those with pcs-edit-section-title are editable, but really any h-level header could be pulled
            let sectionTitle = try soupSection.select("h2, h3, h4, h5, h6, h7").first()?.text()
            guard let sectionIdentifier = try Int(soupSection.attr("data-mw-section-id")) else {
                return nil
            }
                
            return ArticleInspectorSection(title: sectionTitle, identifier: sectionIdentifier, sections: convertedSections, paragraphs: paragraphs)
            
        } catch (let error) {
            print(error)
            return nil
        }
        
    }
    
    func fetchAnnotatedHTML(title: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://wikiwho-ios-experiments.wmflabs.org/whocolor/\(title)/")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data else {
                print("Missing data from URLSession.")
                completion(nil)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("JSON in incorrect format.")
                    completion(nil)
                    return
                }
                
                guard let annotatedHTML = json["extended_html"] as? String else {
                    print("Missing extended_html.")
                    completion(nil)
                    return
                }
                
                completion(annotatedHTML)
                
            } catch (let error) {
                completion(nil)
            }
        }
        task.resume()
    }

}
