import Foundation
import SwiftUI
import UIKit

public struct HtmlUtils {
    
    // MARK: - Shared - Nested Types
    
    public struct Styles {
        let font: UIFont
        let boldFont: UIFont
        let italicsFont: UIFont
        let boldItalicsFont: UIFont
        let color: UIColor
        let linkColor: UIColor?
        let strongColor: UIColor?
        let lineSpacing: CGFloat
        let listIndent: String
        
        public init(font: UIFont, boldFont: UIFont, italicsFont: UIFont, boldItalicsFont: UIFont, color: UIColor, linkColor: UIColor?, strongColor: UIColor? = nil, lineSpacing: CGFloat, listIndent: String = HtmlUtils.defaultListIndent) {
            self.font = font
            self.boldFont = boldFont
            self.italicsFont = italicsFont
            self.boldItalicsFont = boldItalicsFont
            self.color = color
            self.linkColor = linkColor
            self.strongColor = strongColor
            self.lineSpacing = lineSpacing
            self.listIndent = listIndent
        }
    }
    
    private enum ListType {
        case ordered
        case unordered
    }
    
    private struct StyleData {
        var openNSRanges: [NSRange] = []
        var completeNSRanges: [NSRange] = []
        var targetAttributeValues: [String] = []
    }
    
    private struct AllStyleData {
        let bold: StyleData
        let italics: StyleData
        let link: StyleData
        let `subscript`: StyleData
        let superscript: StyleData
        let strikethorugh: StyleData
        let underline: StyleData
        let strong: StyleData
    }
    
    private struct ListInsertData {
        let text: String
        let index: Int
        let stringIndex: String.Index
    }
    
    private struct TagRemoveData {
        let range: NSRange
    }
    
    private struct TagAndContentRemoveData {
        let range: NSRange
    }
    
    private struct ElementReplaceData {
        let range: NSRange
        let replaceText: String
    }
    
    // MARK: - Shared - Properties
    
    public static let defaultListIndent = "    "

    // MARK: - NSAttributedString - Public
    
    public static func nsAttributedStringFromHtml(_ html: String, styles: Styles) throws -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: html)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = styles.lineSpacing
        let attributes: [NSAttributedString.Key : Any] = [
            .font: styles.font,
            .foregroundColor: styles.color,
            .paragraphStyle: paragraphStyle
        ]
        attributedString.setAttributes(attributes, range: html.fullNSRange)
        
        let listInsertData = try listInsertData(html: html, styles: styles)
        insertListData(into: attributedString, listInsertData: listInsertData, styles: styles)
        
        let allStyleData = try allStyleData(html: attributedString.string)
        addStyling(to: attributedString, allStyleData: allStyleData, styles: styles)
        
        let tagAndContentRemoveData = try tagAndContentRemoveData(html: attributedString.string)
        removeHtmlTagAndContent(from: attributedString, tagAndContentRemoveData: tagAndContentRemoveData)
        
        let lineBreakReplaceData = try lineBreakReplaceData(html: attributedString.string)
        replaceLineBreaks(from: attributedString, lineBreakReplaceData: lineBreakReplaceData)
        
        let tagRemoveData = try tagRemoveData(html: attributedString.string)
        removeHtmlTags(from: attributedString, tagRemoveData: tagRemoveData)
        
        let entityReplaceData = try entityReplaceData(html: attributedString.string)
        replaceEntities(from: attributedString, entityReplaceData: entityReplaceData)
        
        return attributedString
    }
    
    // MARK: - NSAttributedString - Private
    
    private static func insertListData(into nsAttributedString: NSMutableAttributedString, listInsertData: [ListInsertData], styles: Styles) {
        for insertData in listInsertData.reversed() {
            let insertAttString = NSAttributedString(string: insertData.text, attributes: [
                .foregroundColor: styles.color,
                .font: styles.font
            ])
            nsAttributedString.insert(insertAttString, at: insertData.index)
        }
    }
    
    private static func addStyling(to nsAttributedString: NSMutableAttributedString, allStyleData: AllStyleData, styles: Styles) {

        // Style Bold
        for boldRange in allStyleData.bold.completeNSRanges {
            nsAttributedString.addAttribute(.font, value: styles.boldFont, range: boldRange)
        }
        
        // Style Italic
        for italicRange in allStyleData.italics.completeNSRanges {
            nsAttributedString.addAttribute(.font, value: styles.italicsFont, range: italicRange)
        }
        
        // Style Bold and Italic, needs extra nested looping handling
        
        for italicRange in allStyleData.italics.completeNSRanges {
            
            for boldRange in allStyleData.bold.completeNSRanges {
                if NSIntersectionRange(boldRange, italicRange) == boldRange {
                    nsAttributedString.addAttribute(.font, value: styles.boldItalicsFont, range: boldRange)
                }
            }
        }
        
        for boldRange in allStyleData.bold.completeNSRanges {
            
            for italicRange in allStyleData.italics.completeNSRanges {
                if NSIntersectionRange(italicRange, boldRange) == italicRange {
                    nsAttributedString.addAttribute(.font, value: styles.boldItalicsFont, range: italicRange)
                }
            }
        }
        
        // Style Link
        if let linkColor = styles.linkColor {
            for (linkRange, linkHref) in zip(allStyleData.link.completeNSRanges, allStyleData.link.targetAttributeValues) {
                nsAttributedString.addAttribute(.foregroundColor, value: linkColor, range: linkRange)
                nsAttributedString.addAttribute(.link, value: linkHref, range: linkRange)
            }
        }
        
        // Style Subscript
        for subRange in allStyleData.subscript.completeNSRanges {
            nsAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: subscriptPointSize(styles: styles)), range: subRange)
            nsAttributedString.addAttribute(.baselineOffset, value: subscriptOffset(styles: styles), range: subRange)
        }
        
        // Style Superscript
        for supRange in allStyleData.superscript.completeNSRanges {
            nsAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: superscriptPointSize(styles: styles)), range: supRange)
            nsAttributedString.addAttribute(.baselineOffset, value: superscriptOffset(styles: styles), range: supRange)
        }
        
        // Style Strikethrough
        for strikethroughRange in allStyleData.strikethorugh.completeNSRanges {
            nsAttributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: strikethroughRange)
        }
        
        // Style Underline
        for underlineRange in allStyleData.underline.completeNSRanges {
            nsAttributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: underlineRange)
        }
        
        // Style Strong
        if let strongColor = styles.strongColor {
            for strongRange in allStyleData.strong.completeNSRanges {
                nsAttributedString.addAttribute(.foregroundColor, value: strongColor, range: strongRange)
            }
        }
    }
    
    private static func removeHtmlTagAndContent(from nsAttributedString: NSMutableAttributedString, tagAndContentRemoveData: [TagAndContentRemoveData]) {
        for removeData in tagAndContentRemoveData.reversed() {
            nsAttributedString.replaceCharacters(in: removeData.range, with: "")
        }
    }
    
    private static func removeHtmlTags(from nsAttributedString: NSMutableAttributedString, tagRemoveData: [TagRemoveData]) {
        for removeData in tagRemoveData.reversed() {
            nsAttributedString.replaceCharacters(in: removeData.range, with: "")
        }
    }
    
    private static func replaceLineBreaks(from nsAttributedString: NSMutableAttributedString, lineBreakReplaceData: [ElementReplaceData]) {
        for data in lineBreakReplaceData.reversed() {
            nsAttributedString.replaceCharacters(in: data.range, with: data.replaceText)
        }
    }
    
    private static func replaceEntities(from nsAttributedString: NSMutableAttributedString, entityReplaceData: [ElementReplaceData]) {
        for data in entityReplaceData.reversed() {
            nsAttributedString.replaceCharacters(in: data.range, with: data.replaceText)
        }
    }
    
    // MARK: - AttributedString - Public
    
    public static func attributedStringFromHtml(_ html: String, styles: Styles) throws -> AttributedString {
        
        var attributedString = AttributedString(html)
        attributedString.font = styles.font
        attributedString.foregroundColor = styles.color
        
        let listInsertData = try listInsertData(html: html, styles: styles)
        insertListData(into: &attributedString, listInsertData: listInsertData, styles: styles)
        
        let allStyleData = try allStyleData(html: String(attributedString.characters))
        addStyling(to: &attributedString, allStyleData: allStyleData, styles: styles)

        let tagAndContentRemoveData = try tagAndContentRemoveData(html: String(attributedString.characters))
        removeHtmlTagAndContent(from: &attributedString, tagAndContentRemoveData: tagAndContentRemoveData)
        
        let lineBreakReplaceData = try lineBreakReplaceData(html: String(attributedString.characters))
        replaceLineBreaks(from: &attributedString, lineBreakReplaceData: lineBreakReplaceData)
        
        let tagRemoveData = try tagRemoveData(html: String(attributedString.characters))
        removeHtmlTags(from: &attributedString, tagRemoveData: tagRemoveData)
        
        let entityReplaceData = try entityReplaceData(html: String(attributedString.characters))
        replaceEntities(from: &attributedString, entityReplaceData: entityReplaceData)
        
        return attributedString
    }
    
    // MARK: - AttributedString - Private
    
    private static func insertListData(into attributedString: inout AttributedString, listInsertData: [ListInsertData], styles: Styles) {
        for insertData in listInsertData.reversed() {
            
            if let attStringIndex = AttributedString.Index(insertData.stringIndex, within: attributedString) {
                var insertAttString = AttributedString(insertData.text)
                insertAttString.foregroundColor = styles.color
                insertAttString.font = styles.font
                attributedString.insert(insertAttString, at: attStringIndex)
            }
        }
    }
    
    private static func addStyling(to attributedString: inout AttributedString, allStyleData: AllStyleData, styles: Styles) {
        
        // Style Bold
        for boldNSRange in allStyleData.bold.completeNSRanges {
            if let boldRange = Range(boldNSRange, in: attributedString) {
                attributedString[boldRange].font = styles.boldFont
            }
        }
        
        // Style Italic
        for italicNSRange in allStyleData.italics.completeNSRanges {
            if let italicRange = Range(italicNSRange, in: attributedString) {
                attributedString[italicRange].font = styles.italicsFont
            }
        }
        
        // Style Bold and Italic, needs extra nested looping handling
        for italicNSRange in allStyleData.italics.completeNSRanges {
            
            for boldNSRange in allStyleData.bold.completeNSRanges {
                
                if let boldRange = Range(boldNSRange, in: attributedString),
                   let italicRange = Range(italicNSRange, in: attributedString) {
                    
                    if boldRange.clamped(to: italicRange) == boldRange {
                        attributedString[boldRange].font = styles.boldItalicsFont
                    }
                }
            }
        }
        
        for boldNSRange in allStyleData.bold.completeNSRanges {
            
            for italicNSRange in allStyleData.italics.completeNSRanges {
                
                if let boldRange = Range(boldNSRange, in: attributedString),
                   let italicRange = Range(italicNSRange, in: attributedString) {
                    
                    if italicRange.clamped(to: boldRange) == italicRange {
                        attributedString[italicRange].font = styles.boldItalicsFont
                    }
                    
                }
            }
        }
        
        // Style Link
        if let linkColor = styles.linkColor {
            for (linkNSRange, hrefString) in zip(allStyleData.link.completeNSRanges, allStyleData.link.targetAttributeValues) {
                if let linkRange = Range(linkNSRange, in: attributedString) {
                    attributedString[linkRange].foregroundColor = linkColor
                    attributedString[linkRange].link = URL(string:hrefString)
                }
            }
        }
        
        // Style Subscript
        for subNSRange in allStyleData.subscript.completeNSRanges {
            if let subRange = Range(subNSRange, in: attributedString) {
                attributedString[subRange].font = UIFont.systemFont(ofSize: subscriptPointSize(styles: styles))
                attributedString[subRange].baselineOffset = subscriptOffset(styles: styles)
            }
        }
        
        // Style Superscript
        for supNSRange in allStyleData.superscript.completeNSRanges {
            if let supRange = Range(supNSRange, in: attributedString) {
                attributedString[supRange].font = UIFont.systemFont(ofSize: superscriptPointSize(styles: styles))
                attributedString[supRange].baselineOffset = superscriptOffset(styles: styles)
            }
        }
        
        // Style Strikethrough
        for strikethroughNSRange in allStyleData.strikethorugh.completeNSRanges {
            if let strikethroughRange = Range(strikethroughNSRange, in: attributedString) {
                attributedString[strikethroughRange].strikethroughStyle = .single
            }
        }
        
        // Style Underline
        for underlineNSRange in allStyleData.underline.completeNSRanges {
            if let underlineRange = Range(underlineNSRange, in: attributedString) {
                attributedString[underlineRange].underlineStyle = .single
            }
        }

        // Style Strong
        if let strongColor = styles.strongColor {
            for strongNSRange in allStyleData.strong.completeNSRanges {
                if let strongRange  = Range(strongNSRange, in: attributedString) {
                    attributedString[strongRange].foregroundColor = strongColor
                }
            }
        }
    }
    
    private static func removeHtmlTagAndContent(from attributedString: inout AttributedString, tagAndContentRemoveData: [TagAndContentRemoveData]) {
        
        for removeData in tagAndContentRemoveData.reversed() {
            
            guard let tagRange = Range(removeData.range, in: attributedString) else {
                continue
            }
            
            attributedString.removeSubrange(tagRange)
        }
    }
    
    private static func removeHtmlTags(from attributedString: inout AttributedString, tagRemoveData: [TagRemoveData]) {
        
        for removeData in tagRemoveData.reversed() {
            
            guard let tagRange = Range(removeData.range, in: attributedString) else {
                continue
            }
            
            attributedString.removeSubrange(tagRange)
        }
    }
    
    private static func replaceLineBreaks(from attributedString: inout AttributedString, lineBreakReplaceData: [ElementReplaceData]) {
        
        for data in lineBreakReplaceData.reversed() {
            
            guard let range = Range(data.range, in: attributedString) else {
                continue
            }
            
            attributedString.replaceSubrange(range, with: AttributedString(data.replaceText))
        }
    }
    
    private static func replaceEntities(from attributedString: inout AttributedString, entityReplaceData: [ElementReplaceData]) {
        
        for data in entityReplaceData.reversed() {
            
            guard let range = Range(data.range, in: attributedString) else {
                continue
            }
            
            attributedString.replaceSubrange(range, with: AttributedString(data.replaceText))
        }
    }

    public static func stringFromHTML(_ string: String) throws -> String {
        let regex = try htmlTagRegex()
        let cleanString = regex.stringByReplacingMatches(in: string, options: [], range: string.fullNSRange, withTemplate: "")
        let entityReplaceData = try entityReplaceData(html: cleanString)
            let mutableCleanString = NSMutableString(string: cleanString)
            for data in entityReplaceData.reversed() {
                mutableCleanString.replaceCharacters(in: data.range, with: data.replaceText)
            }
            return mutableCleanString as String
    }

    // MARK: - Shared - Private
    
    private static func htmlTagRegex() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: "(?:<)([\\/a-z0-9]*)(?:\\s?)([^>]*)(?:>)")
    }
    
    private static func lineBreakRegex() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: "<br(?: ?\\/?)?>")
    }
    
    private static func entityRegex() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: "&([^\\s;]+);")
    }
    
    private static func subscriptPointSize(styles: Styles) -> CGFloat {
        return styles.font.pointSize * 0.75
    }
    
    private static func subscriptOffset(styles: Styles) -> CGFloat {
        return -(styles.font.pointSize * 0.15)
    }
    
    private static func superscriptPointSize(styles: Styles) -> CGFloat {
        return styles.font.pointSize * 0.75
    }
    
    private static func superscriptOffset(styles: Styles) -> CGFloat {
        return styles.font.pointSize * 0.35
    }
    
    private static func listInsertData(html: String, styles: Styles) throws -> [ListInsertData] {
        
        // First enumerate through all list tags and capture insert data
        let listTagRegex = try NSRegularExpression(pattern: "(?:<)((?:\\/?)(?:ol|ul|li))(?:\\s?)([^>]*)(?:>)")
        var types: [ListType] = []
        var indent: Int = 0
        var orderedListCounts: [Int] = []
        var inserts: [ListInsertData] = []
        listTagRegex.enumerateMatches(in: html, range: html.fullNSRange) { match, flags, stop in
            
            guard let tagNSRange = match?.range(at: 0),
                  let tagRange = Range(tagNSRange, in: html),
                  let tagNameNSRange = match?.range(at: 1),
                  let tagNameRange = Range(tagNameNSRange, in: html) else {
                return
            }
            
            let tagNameString = html[tagNameRange]
            if tagNameString == "ol" {
                types.append(.ordered)
                indent = indent + 1
                orderedListCounts.append(0)
            } else if tagNameString == "ul" {
                types.append(.unordered)
                indent = indent + 1
            }
            
            if tagNameString == "/ol" {
                types.removeLast()
                indent = indent - 1
                orderedListCounts.removeLast()
            } else if tagNameString == "/ul" {
                types.removeLast()
                indent = indent - 1
            }
            
            if tagNameString == "li" {
                
                guard let currentListType = types.last else {
                    return
                }
                
                if case .ordered = currentListType {
                    if let lastOrderedListCount = orderedListCounts.popLast() {
                        orderedListCounts.append(lastOrderedListCount + 1)
                    }
                }
                
                let spaces = String(repeating: styles.listIndent, count: indent)
                
                var lineBreakPrefix = ""
                if tagRange.lowerBound > html.startIndex {
                    let previousIndex = html.index(before: tagRange.lowerBound)
                    if html[previousIndex] != "\n" {
                        lineBreakPrefix = "\n"
                    }
                }
                
                switch currentListType {
                case .ordered:
                    if let count = orderedListCounts.last {
                        inserts.append(ListInsertData(text: "\(lineBreakPrefix)\(spaces)\(count). ", index: tagNSRange.upperBound, stringIndex: tagRange.upperBound))
                    }
                case .unordered:
                    inserts.append(ListInsertData(text: "\(lineBreakPrefix)\(spaces)• ", index: tagNSRange.upperBound, stringIndex: tagRange.upperBound))
                }
            }
        }
        
        return inserts
    }
    
    private static func allStyleData(html: String) throws -> AllStyleData {
        
        let htmlTagRegex = try htmlTagRegex()
        
        var boldStyleData = StyleData()
        var italicsStyleData = StyleData()
        var linkStyleData = StyleData()
        var subscriptStyleData = StyleData()
        var superscriptStyleData = StyleData()
        var strikethroughStyleData = StyleData()
        var underlineStyleData = StyleData()
        var strongStyleData = StyleData()

        htmlTagRegex.enumerateMatches(in: html, range: html.fullNSRange) { match, flags, stop in
            
            guard let tagNSRange = match?.range(at: 0),
                  let tagNameNSRange = match?.range(at: 1) else {
                return
            }
            
            updateStyleData(styleData: &boldStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "b", targetAttributeName: nil)
            updateStyleData(styleData: &italicsStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "i", targetAttributeName: nil)
            updateStyleData(styleData: &linkStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "a", targetAttributeName: "href")
            updateStyleData(styleData: &subscriptStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "sub", targetAttributeName: nil)
            updateStyleData(styleData: &superscriptStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "sup", targetAttributeName: nil)
            updateStyleData(styleData: &strikethroughStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "s", targetAttributeName: nil)
            updateStyleData(styleData: &underlineStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "u", targetAttributeName: nil)
            updateStyleData(styleData: &strongStyleData, html: html, tagNSRange: tagNSRange, tagNameNSRange: tagNameNSRange, targetTagName: "strong", targetAttributeName: nil)
        }
        
        return AllStyleData(bold: boldStyleData, italics: italicsStyleData, link: linkStyleData, subscript: subscriptStyleData, superscript: superscriptStyleData, strikethorugh: strikethroughStyleData, underline: underlineStyleData, strong: strongStyleData)
    }
    
    private static func updateStyleData(styleData: inout StyleData, html: String, tagNSRange: NSRange, tagNameNSRange: NSRange, targetTagName: String, targetAttributeName: String?) {
        
        guard let tagNameRange = Range(tagNameNSRange, in: html),
        let tagRange = Range(tagNSRange, in: html) else {
            return
        }
        
        let tagNameString = html[tagNameRange]
        let tagString = String(html[tagRange])
        
        // Check for open tag, append to open tag ranges
        if tagNameString == targetTagName {
            styleData.openNSRanges.append(tagNSRange)
            
            // If needed, determine and append target attribute value
            updateStyleAttributeDataIfNeeded(styleData: &styleData, tagString: tagString, targetAttributeName: targetAttributeName)
        
        // Check for close tag, then grab associated open tag range and create completed range with open and close ranges. Append to ranges.
        } else if tagNameString == "/\(targetTagName)",
                  let lastOpenNSRange = styleData.openNSRanges.popLast() {
            let completeNSRange = NSRange(location: lastOpenNSRange.location, length: (tagNSRange.location + tagNSRange.length) - lastOpenNSRange.location)
            styleData.completeNSRanges.append(completeNSRange)
        }
    }
    
    private static func updateStyleAttributeDataIfNeeded(styleData: inout StyleData, tagString: String, targetAttributeName: String?) {
        
        guard let targetAttributeName,
              let attributeValueRegex = try? NSRegularExpression(pattern: "\(targetAttributeName)[\\s]*=[\\s]*[\"']?[\\s]*((?:.(?![\"']?\\s+(?:\\S+)=|[>\"']))+.)[\\s]*[\"']?") else {
            return
        }
        
        let attrMatch = attributeValueRegex.firstMatch(in: tagString, range: tagString.fullNSRange)
       if let attrMatchNSRange = attrMatch?.range(at: 1),
          let attrMatchRange = Range(attrMatchNSRange, in: tagString) {
           let attrMatchValue = String(tagString[attrMatchRange])
           styleData.targetAttributeValues.append(attrMatchValue)
       }
    }
    
    private static func tagAndContentRemoveData(html: String) throws -> [TagAndContentRemoveData] {
        let regexScript = try NSRegularExpression(pattern: "<script.*?>.*?<\\/script>")
        let regexStyle = try NSRegularExpression(pattern: "<style.*?>.*?<\\/style>")
        
        var data: [TagAndContentRemoveData] = []
        
        let scriptMatches = regexScript.matches(in: html, range: html.fullNSRange)
        let styleMatches = regexStyle.matches(in: html, range: html.fullNSRange)
        for match in scriptMatches {
            data.append(TagAndContentRemoveData(range: match.range(at: 0)))
        }
        
        for match in styleMatches {
            data.append(TagAndContentRemoveData(range: match.range(at: 0)))
        }
        
        return data
    }
    
    private static func tagRemoveData(html: String) throws -> [TagRemoveData] {
        let htmlRegex = try htmlTagRegex()
        
        var data: [TagRemoveData] = []
        let matches = htmlRegex.matches(in: html, range: html.fullNSRange)
        for match in matches {
            data.append(TagRemoveData(range: match.range(at: 0)))
        }
        
        return data
    }
    
    private static func lineBreakReplaceData(html: String) throws -> [ElementReplaceData] {
        let lineBreakRegex = try lineBreakRegex()
        var data: [ElementReplaceData] = []
        let matches = lineBreakRegex.matches(in: html, range: html.fullNSRange)
        for match in matches {
            data.append(ElementReplaceData(range: match.range(at: 0), replaceText: "\n"))
        }
        return data
    }
    
    private static func entityReplaceData(html: String) throws -> [ElementReplaceData] {
        let entityRegex = try entityRegex()
        var data: [ElementReplaceData] = []
        let matches = entityRegex.matches(in: html, range: html.fullNSRange)
        for match in matches {
            
            let range = match.range(at: 0)
            let text = (html as NSString).substring(with: range)
            let replaceText: String?
            
            switch text {
            case "&amp;":
                replaceText = "&"
            case "&nbsp;":
                replaceText = " "
            case "&gt;":
                replaceText = ">"
            case "&lt;":
                replaceText = "<"
            case "&apos;", "&#039;":
                replaceText = "'"
            case "&quot;":
                replaceText = "\""
            case "&ndash;":
                replaceText = "\u{2013}"
            case "&mdash;":
                replaceText = "\u{2014}"
            case "&#8722;":
                replaceText = "\u{2212}"
            default:
                replaceText = nil
            }
            
            if let replaceText {
                data.append(ElementReplaceData(range: range, replaceText: replaceText))
            }
        }
        return data
    }
}

private extension String {
    var fullNSRange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }
}
