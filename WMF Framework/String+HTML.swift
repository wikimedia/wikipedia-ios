import Foundation

extension String {
    /// Converts HTML string to NSAttributedString by handling a limited subset of tags. Optionally bolds an additional string based on matching.
    ///
    /// This is used instead of alloc/init'ing the attributed string with @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} because that approach proved to be slower and could't be called from a background thread. More info: https://developer.apple.com/documentation/foundation/nsattributedstring/1524613-initwithdata
    ///
    /// - Parameter textStyle: DynamicTextStyle to use with the resulting string
    /// - Parameter boldWeight: Font weight for bolded parts of the string
    /// - Parameter traitCollection: trait collection for font selection
    /// - Parameter color: Text color
    /// - Parameter handlingLinks: Whether or not link tags should be parsed and turned into links in the resulting string
    /// - Parameter linkColor: Link text color
    /// - Parameter handlingLists: Whether or not list tags should be parsed and styled in the resulting string
    /// - Parameter handlingSuperSubscripts: whether or not super and subscript tags should be parsed and styled in the resulting string
    /// - Parameter handlingAnnotationTags: whether or not to seek out annotation spans and highlight their inner text. Must be include annotationTokenIDs and an annotationHighlight for this to work
    /// - Parameter annotationTokenIDs: the token IDs for this method to seek out for highlighting. Looks for span tags with attributes containing "id=\"token-nnn" where nnn is the tokenID that you want to highlight
    /// - Parameter annotationHighlight: the background highlight color applied to annotation text
    /// - Parameter tagMapping: Lowercase string tag name to another lowercase string tag name - converts tags, for example, @{@"a":@"b"} will turn <a></a> tags to <b></b> tags
    /// - Parameter additionalTagAttributes: Additional text attributes for given tags - lowercase tag name to attribute key/value pairs
    /// - Returns: the resulting NSMutableAttributedString with styles applied to match the limited set of HTML tags that were parsed
    public func byAttributingHTML(with textStyle: DynamicTextStyle, boldWeight: UIFont.Weight = .semibold, matching traitCollection: UITraitCollection, color: UIColor? = nil, handlingLinks: Bool = true, linkColor: UIColor? = nil, handlingLists: Bool = false, handlingSuperSubscripts: Bool = false, handlingAnnotationTags: Bool = false, annotationTokenIDs: [String] = [], annotationHighlight: UIColor? = nil, tagMapping: [String: String]? = nil, additionalTagAttributes: [String: [NSAttributedString.Key: Any]]? = nil) -> NSMutableAttributedString {
        let font = UIFont.wmf_font(textStyle, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(textStyle.with(weight: boldWeight), compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(textStyle.with(traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        let boldItalicFont = UIFont.wmf_font(textStyle.with(weight: boldWeight, traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        return (self as NSString).wmf_attributedStringFromHTML(with: font, boldFont: boldFont, italicFont: italicFont, boldItalicFont: boldItalicFont, color: color, linkColor: linkColor, handlingLinks: handlingLinks, handlingLists: handlingLists, handlingSuperSubscripts: handlingSuperSubscripts, handlingAnnotationTags: handlingAnnotationTags, annotationTokenIDs: annotationTokenIDs, annotationHighlight: annotationHighlight, tagMapping: tagMapping, additionalTagAttributes: additionalTagAttributes)
    }
    
    public var removingHTML: String {
        return (self as NSString).wmf_stringByRemovingHTML()
    }
}
