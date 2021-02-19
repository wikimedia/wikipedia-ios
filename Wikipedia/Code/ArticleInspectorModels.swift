
import Foundation

protocol ArticleInspectorSentence {
    var rawText: String { get }
}

struct ArticleInspector {
    
    struct Section<T> where T: ArticleInspectorSentence {
        let title: String?
        let identifier: Int
        let sections: [Section]
        let paragraphs: [Paragraph<T>]
    }
    
    struct Paragraph<T> where T: ArticleInspectorSentence {
        let sentences: [T]
    }
    
    struct IndividualSentence: ArticleInspectorSentence {
        let htmlText: String //sentence with html tags. Could be only article content html tags or article content html tags + annotation tags, depending on which html response was used for processing.
        let rawText: String //sentence with no html or annotation tags
    }
    
    struct CombinedSentence: ArticleInspectorSentence {
        let articleText: String //sentence with article content html tags, for seeking out in article content html
        let nativeText: String //sentence with article content html tags and annotation tags, used for turning into NSAttributedStrings for native use
        let rawText: String //sentence with no html or annotation tags
    }
    
    struct HtmlTag {
        let text: String //html tag text, e.g. '<b>'
        let range: NSRange
    }
}
