import Foundation

public struct WKWikitextHtmlUtils {
    
    public struct SelectedInfo {
        let textBeforeSelectedText: String
        let selectedText: String
        let textAfterSelectedText: String
        
        public init(textBeforeSelectedText: String, selectedText: String, textAfterSelectedText: String) {
            self.textBeforeSelectedText = textBeforeSelectedText
            self.selectedText = selectedText
            self.textAfterSelectedText = textAfterSelectedText
        }
    }
    
    
    /// Helper method to detect the range of selected text within a blob of wikitext.
    /// Essentially uses adjacent text next to selected text and seeks out the best range in wikitext, while ignoring wikitext markup.
    /// - Parameters:
    ///   - selectedInfo: Selected Info struct. See `wmf_getSelectedTextEditInfo` in the client app for assistance in pulling this data from a web view.
    ///   - wikitext: Wikitext to search through
    /// - Returns: NSRange of the selected text in wikitext.
    public static func rangeOf(selectedInfo: SelectedInfo, inWikitext wikitext: String) -> NSRange? {
        return nil
    }
}
