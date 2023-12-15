import XCTest
@testable import Components
@testable import ComponentsObjC

final class WKSourceEditorFormatterTests: XCTestCase {
    
    var colors: WKSourceEditorColors!
    var fonts: WKSourceEditorFonts!
    
    var baseFormatter: WKSourceEditorFormatterBase!
    var boldItalicsFormatter: WKSourceEditorFormatterBoldItalics!
    var templateFormatter: WKSourceEditorFormatterTemplate!
    var headingFormatter: WKSourceEditorFormatterHeading!
    var listFormatter: WKSourceEditorFormatterList!
    var referenceFormatter: WKSourceEditorFormatterReference!
    var strikethroughFormatter: WKSourceEditorFormatterStrikethrough!
    var formatters: [WKSourceEditorFormatter] {
        return [baseFormatter, templateFormatter, boldItalicsFormatter, headingFormatter, listFormatter, referenceFormatter, strikethroughFormatter]
    }

    override func setUpWithError() throws {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        
        self.colors = WKSourceEditorColors()
        self.colors.baseForegroundColor = WKTheme.light.text
        self.colors.orangeForegroundColor = WKTheme.light.editorOrange
        self.colors.purpleForegroundColor = WKTheme.light.editorPurple
        self.colors.greenForegroundColor = WKTheme.light.editorGreen
        
        self.fonts = WKSourceEditorFonts()
        self.fonts.baseFont = WKFont.for(.body, compatibleWith: traitCollection)
        self.fonts.boldFont = WKFont.for(.boldBody, compatibleWith: traitCollection)
        self.fonts.italicsFont = WKFont.for(.italicsBody, compatibleWith: traitCollection)
        self.fonts.boldItalicsFont = WKFont.for(.boldItalicsBody, compatibleWith: traitCollection)
        self.fonts.headingFont = WKFont.for(.editorHeading, compatibleWith: traitCollection)
        self.fonts.subheading1Font = WKFont.for(.editorSubheading1, compatibleWith: traitCollection)
        self.fonts.subheading2Font = WKFont.for(.editorSubheading2, compatibleWith: traitCollection)
        self.fonts.subheading3Font = WKFont.for(.editorSubheading3, compatibleWith: traitCollection)
        self.fonts.subheading4Font = WKFont.for(.editorSubheading4, compatibleWith: traitCollection)
        
        self.baseFormatter = WKSourceEditorFormatterBase(colors: colors, fonts: fonts, textAlignment: .left)
        self.boldItalicsFormatter = WKSourceEditorFormatterBoldItalics(colors: colors, fonts: fonts)
        self.templateFormatter = WKSourceEditorFormatterTemplate(colors: colors, fonts: fonts)
        self.headingFormatter = WKSourceEditorFormatterHeading(colors: colors, fonts: fonts)
        self.listFormatter = WKSourceEditorFormatterList(colors: colors, fonts: fonts)
        self.referenceFormatter = WKSourceEditorFormatterReference(colors: colors, fonts: fonts)
        self.strikethroughFormatter = WKSourceEditorFormatterStrikethrough(colors: colors, fonts: fonts)
    }

    override func tearDownWithError() throws {
    }

    func testBoldItalicFormatter() {
        let string = "The quick '''''brown''''' fox jumps over the '''''lazy''''' dog"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var opening1Range = NSRange(location: 0, length: 0)
        let opening1Attributes = mutAttributedString.attributes(at: 10, effectiveRange: &opening1Range)
        
        var content1Range = NSRange(location: 0, length: 0)
        let content1Attributes = mutAttributedString.attributes(at: 15, effectiveRange: &content1Range)
        
        var closing1Range = NSRange(location: 0, length: 0)
        let closing1Attributes = mutAttributedString.attributes(at: 20, effectiveRange: &closing1Range)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 25, effectiveRange: &base2Range)
        
        var opening2Range = NSRange(location: 0, length: 0)
        let opening2Attributes = mutAttributedString.attributes(at: 45, effectiveRange: &opening2Range)
        
        var content2Range = NSRange(location: 0, length: 0)
        let content2Attributes = mutAttributedString.attributes(at: 50, effectiveRange: &content2Range)
        
        var closing2Range = NSRange(location: 0, length: 0)
        let closing2Attributes = mutAttributedString.attributes(at: 54, effectiveRange: &closing2Range)
        
        var base3Range = NSRange(location: 0, length: 0)
        let base3Attributes = mutAttributedString.attributes(at: 59, effectiveRange: &base3Range)
        
        // "The quick "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 10, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "'''''"
        XCTAssertEqual(opening1Range.location, 10, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening1Range.length, 5, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold italic opening formatting")
        
        // "brown"
        XCTAssertEqual(content1Range.location, 15, "Incorrect bold italic content formatting")
        XCTAssertEqual(content1Range.length, 5, "Incorrect bold italic content formatting")
        XCTAssertEqual(content1Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(content1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "'''''"
        XCTAssertEqual(closing1Range.location, 20, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing1Range.length, 5, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold italic closing formatting")
        
        // " fox jumps over the "
        XCTAssertEqual(base2Range.location, 25, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 20, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "'''''"
        XCTAssertEqual(opening2Range.location, 45, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening2Range.length, 5, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold italic opening formatting")
        XCTAssertEqual(opening2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold italic opening formatting")
        
        // "lazy"
        XCTAssertEqual(content2Range.location, 50, "Incorrect bold italic content formatting")
        XCTAssertEqual(content2Range.length, 4, "Incorrect bold italic content formatting")
        XCTAssertEqual(content2Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(content2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "'''''"
        XCTAssertEqual(closing2Range.location, 54, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing2Range.length, 5, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold italic closing formatting")
        XCTAssertEqual(closing2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold italic closing formatting")
        
        // " dog"
        XCTAssertEqual(base3Range.location, 59, "Incorrect base formatting")
        XCTAssertEqual(base3Range.length, 4, "Incorrect base formatting")
        XCTAssertEqual(base3Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base3Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testBold() {
        let string = "The '''quick''' brown fox jumps over the lazy dog"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var opening1Range = NSRange(location: 0, length: 0)
        let opening1Attributes = mutAttributedString.attributes(at: 4, effectiveRange: &opening1Range)
        
        var content1Range = NSRange(location: 0, length: 0)
        let content1Attributes = mutAttributedString.attributes(at: 7, effectiveRange: &content1Range)
        
        var closing1Range = NSRange(location: 0, length: 0)
        let closing1Attributes = mutAttributedString.attributes(at: 12, effectiveRange: &closing1Range)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 15, effectiveRange: &base2Range)
        
        // "The "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 4, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "'''"
        XCTAssertEqual(opening1Range.location, 4, "Incorrect bold opening formatting")
        XCTAssertEqual(opening1Range.length, 3, "Incorrect bold opening formatting")
        XCTAssertEqual(opening1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold opening formatting")
        XCTAssertEqual(opening1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold opening formatting")
        
        // "quick"
        XCTAssertEqual(content1Range.location, 7, "Incorrect bold content formatting")
        XCTAssertEqual(content1Range.length, 5, "Incorrect bold content formatting")
        XCTAssertEqual(content1Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect bold content formatting")
        XCTAssertEqual(content1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold content formatting")
        
        // "'''"
        XCTAssertEqual(closing1Range.location, 12, "Incorrect bold closing formatting")
        XCTAssertEqual(closing1Range.length, 3, "Incorrect bold closing formatting")
        XCTAssertEqual(closing1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold closing formatting")
        XCTAssertEqual(closing1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold closing formatting")
        
        // " brown fox jumps over the lazy dog"
        XCTAssertEqual(base2Range.location, 15, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 34, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testItalics() {
        let string = "The quick brown ''fox'' jumps over the lazy dog"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var opening1Range = NSRange(location: 0, length: 0)
        let opening1Attributes = mutAttributedString.attributes(at: 16, effectiveRange: &opening1Range)
        
        var content1Range = NSRange(location: 0, length: 0)
        let content1Attributes = mutAttributedString.attributes(at: 18, effectiveRange: &content1Range)
        
        var closing1Range = NSRange(location: 0, length: 0)
        let closing1Attributes = mutAttributedString.attributes(at: 21, effectiveRange: &closing1Range)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 23, effectiveRange: &base2Range)
        
        // "The quick brown "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 16, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "''"
        XCTAssertEqual(opening1Range.location, 16, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Range.length, 2, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic opening formatting")
        
        // "fox"
        XCTAssertEqual(content1Range.location, 18, "Incorrect italic content formatting")
        XCTAssertEqual(content1Range.length, 3, "Incorrect italic content formatting")
        XCTAssertEqual(content1Attributes[.font] as! UIFont, fonts.italicsFont, "Incorrect italic content formatting")
        XCTAssertEqual(content1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect italic content formatting")
        
        // "''"
        XCTAssertEqual(closing1Range.location, 21, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Range.length, 2, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic closing formatting")
        
        // " jumps over the lazy dog"
        XCTAssertEqual(base2Range.location, 23, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 24, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testItalicsWithApostrophe() {
        let string = "Apostrophes ''shouldn't throw off'' formatting"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var opening1Range = NSRange(location: 0, length: 0)
        let opening1Attributes = mutAttributedString.attributes(at: 12, effectiveRange: &opening1Range)
        
        var content1Range = NSRange(location: 0, length: 0)
        let content1Attributes = mutAttributedString.attributes(at: 14, effectiveRange: &content1Range)
        
        var closing1Range = NSRange(location: 0, length: 0)
        let closing1Attributes = mutAttributedString.attributes(at: 33, effectiveRange: &closing1Range)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 35, effectiveRange: &base2Range)
        
        // "Apostrophes "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 12, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "''"
        XCTAssertEqual(opening1Range.location, 12, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Range.length, 2, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect italic opening formatting")
        XCTAssertEqual(opening1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold italic opening formatting")
        
        // "shouldn't throw off"
        XCTAssertEqual(content1Range.location, 14, "Incorrect italic content formatting")
        XCTAssertEqual(content1Range.length, 19, "Incorrect italic content formatting")
        XCTAssertEqual(content1Attributes[.font] as! UIFont, fonts.italicsFont, "Incorrect italic content formatting")
        XCTAssertEqual(content1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect italic content formatting")
        
        // "''"
        XCTAssertEqual(closing1Range.location, 33, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Range.length, 2, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect italic closing formatting")
        XCTAssertEqual(closing1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic closing formatting")
        
        // " formatting"
        XCTAssertEqual(base2Range.location, 35, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 11, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testItalicsNestedInBold() {
        let string = "one '''two ''three'' four ''five'' six''' seven"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var openingBoldRange = NSRange(location: 0, length: 0)
        let openingBoldAttributes = mutAttributedString.attributes(at: 4, effectiveRange: &openingBoldRange)
        
        var contentBold1Range = NSRange(location: 0, length: 0)
        let contentBold1Attributes = mutAttributedString.attributes(at: 7, effectiveRange: &contentBold1Range)
        
        var openingItalics1Range = NSRange(location: 0, length: 0)
        let openingItalics1Attributes = mutAttributedString.attributes(at: 11, effectiveRange: &openingItalics1Range)
        
        var contentBoldItalics1Range = NSRange(location: 0, length: 0)
        let contentBoldItalics1Attributes = mutAttributedString.attributes(at: 13, effectiveRange: &contentBoldItalics1Range)
        
        var closingItalics1Range = NSRange(location: 0, length: 0)
        let closingItalics1Attributes = mutAttributedString.attributes(at: 18, effectiveRange: &closingItalics1Range)
        
        var contentBold2Range = NSRange(location: 0, length: 0)
        let contentBold2Attributes = mutAttributedString.attributes(at: 20, effectiveRange: &contentBold2Range)
        
        var openingItalics2Range = NSRange(location: 0, length: 0)
        let openingItalics2Attributes = mutAttributedString.attributes(at: 26, effectiveRange: &openingItalics2Range)
        
        var contentBoldItalics2Range = NSRange(location: 0, length: 0)
        let contentBoldItalics2Attributes = mutAttributedString.attributes(at: 28, effectiveRange: &contentBoldItalics2Range)
        
        var closingItalics2Range = NSRange(location: 0, length: 0)
        let closingItalics2Attributes = mutAttributedString.attributes(at: 32, effectiveRange: &closingItalics2Range)
        
        var contentBold3Range = NSRange(location: 0, length: 0)
        let contentBold3Attributes = mutAttributedString.attributes(at: 34, effectiveRange: &contentBold3Range)
        
        var closingBoldRange = NSRange(location: 0, length: 0)
        let closingBoldAttributes = mutAttributedString.attributes(at: 38, effectiveRange: &closingBoldRange)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 41, effectiveRange: &base2Range)
        
        // "one "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 4, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "'''"
        XCTAssertEqual(openingBoldRange.location, 4, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBoldRange.length, 3, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBoldAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBoldAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold opening formatting")
        
        // "two "
        XCTAssertEqual(contentBold1Range.location, 7, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold1Range.length, 4, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold1Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold content formatting")
        
        // "''"
        XCTAssertEqual(openingItalics1Range.location, 11, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics1Range.length, 2, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics1Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic opening formatting")
        
        // "three"
        XCTAssertEqual(contentBoldItalics1Range.location, 13, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Range.length, 5, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "''"
        XCTAssertEqual(closingItalics1Range.location, 18, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics1Range.length, 2, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics1Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic closing formatting")
        
        // " four "
        XCTAssertEqual(contentBold2Range.location, 20, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold2Range.length, 6, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold2Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold content formatting")
        
        // "''"
        XCTAssertEqual(openingItalics2Range.location, 26, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics2Range.length, 2, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics2Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect italic opening formatting")
        XCTAssertEqual(openingItalics2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic opening formatting")
        
        // "five"
        XCTAssertEqual(contentBoldItalics2Range.location, 28, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Range.length, 4, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "''"
        XCTAssertEqual(closingItalics2Range.location, 32, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics2Range.length, 2, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics2Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect italic closing formatting")
        XCTAssertEqual(closingItalics2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italic closing formatting")
        
        // " six"
        XCTAssertEqual(contentBold3Range.location, 34, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold3Range.length, 4, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold3Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect bold content formatting")
        XCTAssertEqual(contentBold3Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold content formatting")
        
        // "'''"
        XCTAssertEqual(closingBoldRange.location, 38, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBoldRange.length, 3, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBoldAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBoldAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold closing formatting")
        
        // " seven"
        XCTAssertEqual(base2Range.location, 41, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 6, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testBoldNestedInItalics() {
        let string = "one ''two '''three''' four '''five''' six'' seven"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var openingItalicsRange = NSRange(location: 0, length: 0)
        let openingItalicsAttributes = mutAttributedString.attributes(at: 4, effectiveRange: &openingItalicsRange)
        
        var contentItalics1Range = NSRange(location: 0, length: 0)
        let contentItalics1Attributes = mutAttributedString.attributes(at: 6, effectiveRange: &contentItalics1Range)
        
        var openingBold1Range = NSRange(location: 0, length: 0)
        let openingBold1Attributes = mutAttributedString.attributes(at: 10, effectiveRange: &openingBold1Range)
        
        var contentBoldItalics1Range = NSRange(location: 0, length: 0)
        let contentBoldItalics1Attributes = mutAttributedString.attributes(at: 13, effectiveRange: &contentBoldItalics1Range)
        
        var closingBold1Range = NSRange(location: 0, length: 0)
        let closingBold1Attributes = mutAttributedString.attributes(at: 18, effectiveRange: &closingBold1Range)
        
        var contentItalics2Range = NSRange(location: 0, length: 0)
        let contentItalics2Attributes = mutAttributedString.attributes(at: 21, effectiveRange: &contentItalics2Range)
        
        var openingBold2Range = NSRange(location: 0, length: 0)
        let openingBold2Attributes = mutAttributedString.attributes(at: 27, effectiveRange: &openingBold2Range)
        
        var contentBoldItalics2Range = NSRange(location: 0, length: 0)
        let contentBoldItalics2Attributes = mutAttributedString.attributes(at: 30, effectiveRange: &contentBoldItalics2Range)
        
        var closingBold2Range = NSRange(location: 0, length: 0)
        let closingBold2Attributes = mutAttributedString.attributes(at: 34, effectiveRange: &closingBold2Range)
        
        var contentItalics3Range = NSRange(location: 0, length: 0)
        let contentItalics3Attributes = mutAttributedString.attributes(at: 37, effectiveRange: &contentItalics3Range)
        
        var closingItalicsRange = NSRange(location: 0, length: 0)
        let closingItalicsAttributes = mutAttributedString.attributes(at: 41, effectiveRange: &closingItalicsRange)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 43, effectiveRange: &base2Range)
        
        // "one "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 4, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "''"
        XCTAssertEqual(openingItalicsRange.location, 4, "Incorrect italics opening formatting")
        XCTAssertEqual(openingItalicsRange.length, 2, "Incorrect italics opening formatting")
        XCTAssertEqual(openingItalicsAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect italics opening formatting")
        XCTAssertEqual(openingItalicsAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italics opening formatting")
        
        // "two "
        XCTAssertEqual(contentItalics1Range.location, 6, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics1Range.length, 4, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics1Attributes[.font] as! UIFont, fonts.italicsFont, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect italics content formatting")
        
        // "'''"
        XCTAssertEqual(openingBold1Range.location, 10, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold1Range.length, 3, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold1Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold opening formatting")
        
        // "three"
        XCTAssertEqual(contentBoldItalics1Range.location, 13, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Range.length, 5, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "'''"
        XCTAssertEqual(closingBold1Range.location, 18, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold1Range.length, 3, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold1Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold1Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold closing formatting")
        
        // " four "
        XCTAssertEqual(contentItalics2Range.location, 21, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics2Range.length, 6, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics2Attributes[.font] as! UIFont, fonts.italicsFont, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect italics content formatting")
        
        // "'''"
        XCTAssertEqual(openingBold2Range.location, 27, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold2Range.length, 3, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold2Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold opening formatting")
        XCTAssertEqual(openingBold2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold opening formatting")
        
        // "five"
        XCTAssertEqual(contentBoldItalics2Range.location, 30, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Range.length, 4, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold italic content formatting")
        XCTAssertEqual(contentBoldItalics2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect bold italic content formatting")
        
        // "'''"
        XCTAssertEqual(closingBold2Range.location, 34, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold2Range.length, 3, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold2Attributes[.font] as! UIFont, fonts.boldItalicsFont, "Incorrect bold closing formatting")
        XCTAssertEqual(closingBold2Attributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold closing formatting")
        
        // " six"
        XCTAssertEqual(contentItalics3Range.location, 37, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics3Range.length, 4, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics3Attributes[.font] as! UIFont, fonts.italicsFont, "Incorrect italics content formatting")
        XCTAssertEqual(contentItalics3Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect italics content formatting")
        
        // "''"
        XCTAssertEqual(closingItalicsRange.location, 41, "Incorrect italics closing formatting")
        XCTAssertEqual(closingItalicsRange.length, 2, "Incorrect italics closing formatting")
        XCTAssertEqual(closingItalicsAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect italics closing formatting")
        XCTAssertEqual(closingItalicsAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect italics closing formatting")
        
        // " seven"
        XCTAssertEqual(base2Range.location, 43, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 6, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testHorizontalTemplate1() {
        let string = "Testing simple {{Currentdate}} template example."
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 15, effectiveRange: &templateRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 30, effectiveRange: &base2Range)
        
        // "Testing simple "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 15, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "{{Currentdate}}"
        XCTAssertEqual(templateRange.location, 15, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 15, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
        
        // " template example."
        XCTAssertEqual(base2Range.location, 30, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 18, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testHorizontalTemplate2() {
        let string = "{{Short description|Behavioral pattern found in domestic cats}}"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &templateRange)
        
        // "{{Short description|Behavioral pattern found in domestic cats}}"
        XCTAssertEqual(templateRange.location, 0, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 63, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
    }
    
    func testHorizontalTemplate3() {
        let string = "<ref>{{cite web |url=https://en.wikipedia.org |title=English Wikipedia}}</ref>"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var refOpeningRange = NSRange(location: 0, length: 0)
        let refOpeningAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &refOpeningRange)
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 5, effectiveRange: &templateRange)

        var refClosingRange = NSRange(location: 0, length: 0)
        let refClosingAttributes = mutAttributedString.attributes(at: 72, effectiveRange: &refClosingRange)
        
        // "<ref>"
        XCTAssertEqual(refOpeningRange.location, 0, "Incorrect ref formatting")
        XCTAssertEqual(refOpeningRange.length, 5, "Incorrect ref formatting")
        XCTAssertEqual(refOpeningAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect ref formatting")
        XCTAssertEqual(refOpeningAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect ref formatting")
        
        // "{{cite web |url=https://en.wikipedia.org |title=English Wikipedia}}"
        XCTAssertEqual(templateRange.location, 5, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 67, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
        
        // "</ref>"
        XCTAssertEqual(refClosingRange.location, 72, "Incorrect ref formatting")
        XCTAssertEqual(refClosingRange.length, 6, "Incorrect ref formatting")
        XCTAssertEqual(refClosingAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect ref formatting")
        XCTAssertEqual(refClosingAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect ref formatting")
    }
    
    func testHorizontalNestedTemplate() {
        let string = "Ford Island ({{lang-haw|Poka {{okina}}Ailana}}) is an"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 13, effectiveRange: &templateRange)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 46, effectiveRange: &base2Range)
        
        // "Ford Island ("
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 13, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "{{lang-haw|Poka {{okina}}Ailana}}"
        XCTAssertEqual(templateRange.location, 13, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 33, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
        
        // ") is an"
        XCTAssertEqual(base2Range.location, 46, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 7, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testVerticalStartTemplate1() {
        let string = "{{Infobox officeholder"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &templateRange)

        // "{{Infobox officeholder"
        XCTAssertEqual(templateRange.location, 0, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 22, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
    }
    
    func testVerticalStartTemplate2() {
        let string = "ending of previous sentence. {{cite web"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var baseRange = NSRange(location: 0, length: 0)
        let baseAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &baseRange)
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 29, effectiveRange: &templateRange)

        // "ending of previous sentence. "
        XCTAssertEqual(baseRange.location, 0, "Incorrect base formatting")
        XCTAssertEqual(baseRange.length, 29, "Incorrect base formatting")
        XCTAssertEqual(baseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(baseAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "ending of previous sentence. "
        XCTAssertEqual(templateRange.location, 29, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 10, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect base formatting")
    }
    
    func testVerticalParameterTemplate() {
        let string = "| genus = Felis"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &templateRange)

        // "| genus = Felis"
        XCTAssertEqual(templateRange.location, 0, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 15, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
    }
    
    func testVerticalEndTemplate() {
        let string = "}}"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &templateRange)

        // "}}"
        XCTAssertEqual(templateRange.location, 0, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 2, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
    }
    
    func testVerticalEndRefTemplate() {
        let string = "}}</ref>"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &templateRange)
        
        var refRange = NSRange(location: 0, length: 0)
        let refAttributes = mutAttributedString.attributes(at: 2, effectiveRange: &refRange)

        // "}}</ref>"
        XCTAssertEqual(templateRange.location, 0, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 2, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect template formatting")
        
        XCTAssertEqual(refRange.location, 2, "Incorrect ref formatting")
        XCTAssertEqual(refRange.length, 6, "Incorrect ref formatting")
        XCTAssertEqual(refAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect ref formatting")
        XCTAssertEqual(refAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect ref formatting")
    }
    
    func testHeading() {
        let string = "== Test =="
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var openingRange = NSRange(location: 0, length: 0)
        let openingAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &openingRange)
        
        var contentRange = NSRange(location: 0, length: 0)
        let contentAttributes = mutAttributedString.attributes(at: 2, effectiveRange: &contentRange)
        
        var closingRange = NSRange(location: 0, length: 0)
        let closingAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &closingRange)
        
        // "=="
        XCTAssertEqual(openingRange.location, 0, "Incorrect heading formatting")
        XCTAssertEqual(openingRange.length, 2, "Incorrect heading formatting")
        XCTAssertEqual(openingAttributes[.font] as! UIFont, fonts.headingFont, "Incorrect heading formatting")
        XCTAssertEqual(openingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect heading formatting")
        
        // " Heading Test "
        XCTAssertEqual(contentRange.location, 2, "Incorrect heading formatting")
        XCTAssertEqual(contentRange.length, 6, "Incorrect heading formatting")
        XCTAssertEqual(contentAttributes[.font] as! UIFont, fonts.headingFont, "Incorrect heading formatting")
        XCTAssertEqual(contentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect heading formatting")
        
        // "=="
        XCTAssertEqual(closingRange.location, 8, "Incorrect heading formatting")
        XCTAssertEqual(closingRange.length, 2, "Incorrect heading formatting")
        XCTAssertEqual(closingAttributes[.font] as! UIFont, fonts.headingFont, "Incorrect heading formatting")
        XCTAssertEqual(closingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect heading formatting")
    }
    
    func testSubheading1() {
        let string = "=== Test ==="
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var openingRange = NSRange(location: 0, length: 0)
        let openingAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &openingRange)
        
        var contentRange = NSRange(location: 0, length: 0)
        let contentAttributes = mutAttributedString.attributes(at: 3, effectiveRange: &contentRange)
        
        var closingRange = NSRange(location: 0, length: 0)
        let closingAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &closingRange)
        
        // "=="
        XCTAssertEqual(openingRange.location, 0, "Incorrect subheading1 formatting")
        XCTAssertEqual(openingRange.length, 3, "Incorrect subheading1 formatting")
        XCTAssertEqual(openingAttributes[.font] as! UIFont, fonts.subheading1Font, "Incorrect subheading1 formatting")
        XCTAssertEqual(openingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading1 formatting")
        
        // " Test "
        XCTAssertEqual(contentRange.location, 3, "Incorrect subheading1 formatting")
        XCTAssertEqual(contentRange.length, 6, "Incorrect subheading1 formatting")
        XCTAssertEqual(contentAttributes[.font] as! UIFont, fonts.subheading1Font, "Incorrect subheading1 formatting")
        XCTAssertEqual(contentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect subheading1 formatting")
        
        // "=="
        XCTAssertEqual(closingRange.location, 9, "Incorrect subheading1 formatting")
        XCTAssertEqual(closingRange.length, 3, "Incorrect subheading1 formatting")
        XCTAssertEqual(closingAttributes[.font] as! UIFont, fonts.subheading1Font, "Incorrect subheading1 formatting")
        XCTAssertEqual(closingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading1 formatting")
    }
    
    func testSubheading2() {
        let string = "==== Test ===="
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var openingRange = NSRange(location: 0, length: 0)
        let openingAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &openingRange)
        
        var contentRange = NSRange(location: 0, length: 0)
        let contentAttributes = mutAttributedString.attributes(at: 4, effectiveRange: &contentRange)
        
        var closingRange = NSRange(location: 0, length: 0)
        let closingAttributes = mutAttributedString.attributes(at: 10, effectiveRange: &closingRange)
        
        // "=="
        XCTAssertEqual(openingRange.location, 0, "Incorrect subheading2 formatting")
        XCTAssertEqual(openingRange.length, 4, "Incorrect subheading2 formatting")
        XCTAssertEqual(openingAttributes[.font] as! UIFont, fonts.subheading2Font, "Incorrect subheading2 formatting")
        XCTAssertEqual(openingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading2 formatting")
        
        // " Test "
        XCTAssertEqual(contentRange.location, 4, "Incorrect subheading2 formatting")
        XCTAssertEqual(contentRange.length, 6, "Incorrect subheading2 formatting")
        XCTAssertEqual(contentAttributes[.font] as! UIFont, fonts.subheading2Font, "Incorrect subheading2 formatting")
        XCTAssertEqual(contentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect subheading2 formatting")
        
        // "=="
        XCTAssertEqual(closingRange.location, 10, "Incorrect subheading2 formatting")
        XCTAssertEqual(closingRange.length, 4, "Incorrect subheading2 formatting")
        XCTAssertEqual(closingAttributes[.font] as! UIFont, fonts.subheading2Font, "Incorrect subheading2 formatting")
        XCTAssertEqual(closingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading2 formatting")
    }
    
    func testSubheading3() {
        let string = "===== Test ====="
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var openingRange = NSRange(location: 0, length: 0)
        let openingAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &openingRange)
        
        var contentRange = NSRange(location: 0, length: 0)
        let contentAttributes = mutAttributedString.attributes(at: 5, effectiveRange: &contentRange)
        
        var closingRange = NSRange(location: 0, length: 0)
        let closingAttributes = mutAttributedString.attributes(at: 11, effectiveRange: &closingRange)
        
        // "=="
        XCTAssertEqual(openingRange.location, 0, "Incorrect subheading3 formatting")
        XCTAssertEqual(openingRange.length, 5, "Incorrect subheading3 formatting")
        XCTAssertEqual(openingAttributes[.font] as! UIFont, fonts.subheading3Font, "Incorrect subheading3 formatting")
        XCTAssertEqual(openingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading3 formatting")
        
        // " Test "
        XCTAssertEqual(contentRange.location, 5, "Incorrect subheading3 formatting")
        XCTAssertEqual(contentRange.length, 6, "Incorrect subheading3 formatting")
        XCTAssertEqual(contentAttributes[.font] as! UIFont, fonts.subheading3Font, "Incorrect subheading3 formatting")
        XCTAssertEqual(contentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect subheading3 formatting")
        
        // "=="
        XCTAssertEqual(closingRange.location, 11, "Incorrect subheading3 formatting")
        XCTAssertEqual(closingRange.length, 5, "Incorrect subheading3 formatting")
        XCTAssertEqual(closingAttributes[.font] as! UIFont, fonts.subheading3Font, "Incorrect subheading3 formatting")
        XCTAssertEqual(closingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading3 formatting")
    }
    
    func testSubeading4() {
        let string = "====== Test ======"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var openingRange = NSRange(location: 0, length: 0)
        let openingAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &openingRange)
        
        var contentRange = NSRange(location: 0, length: 0)
        let contentAttributes = mutAttributedString.attributes(at: 6, effectiveRange: &contentRange)
        
        var closingRange = NSRange(location: 0, length: 0)
        let closingAttributes = mutAttributedString.attributes(at: 12, effectiveRange: &closingRange)
        
        // "=="
        XCTAssertEqual(openingRange.location, 0, "Incorrect subheading4 formatting")
        XCTAssertEqual(openingRange.length, 6, "Incorrect subheading4 formatting")
        XCTAssertEqual(openingAttributes[.font] as! UIFont, fonts.subheading4Font, "Incorrect subheading4 formatting")
        XCTAssertEqual(openingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading4 formatting")
        
        // " Test "
        XCTAssertEqual(contentRange.location, 6, "Incorrect subheading4 formatting")
        XCTAssertEqual(contentRange.length, 6, "Incorrect subheading4 formatting")
        XCTAssertEqual(contentAttributes[.font] as! UIFont, fonts.subheading4Font, "Incorrect subheading4 formatting")
        XCTAssertEqual(contentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect subheading4 formatting")
        
        // "=="
        XCTAssertEqual(closingRange.location, 12, "Incorrect subheading4 formatting")
        XCTAssertEqual(closingRange.length, 6, "Incorrect subheading4 formatting")
        XCTAssertEqual(closingAttributes[.font] as! UIFont, fonts.subheading4Font, "Incorrect subheading4 formatting")
        XCTAssertEqual(closingAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect subheading4 formatting")
    }
    
    func testInlineHeading() {
        let string = "Test == Test == Test"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var range = NSRange(location: 0, length: 0)
        let attributes = mutAttributedString.attributes(at: 0, effectiveRange: &range)
        
        // "Test == Test == Test"
        // Inline headings should not format - they must be on their own line.
        XCTAssertEqual(range.location, 0, "Incorrect inline heading formatting")
        XCTAssertEqual(range.length, 20, "Incorrect inline heading formatting")
        XCTAssertEqual(attributes[.font] as! UIFont, fonts.baseFont, "Incorrect inline heading formatting")
        XCTAssertEqual(attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect inline heading formatting")
    }
    func testListSingleBullet() {
        let string = "* Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var bulletRange = NSRange(location: 0, length: 0)
        let bulletAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &bulletRange)
        
        var textRange = NSRange(location: 0, length: 0)
        let textAttributes = mutAttributedString.attributes(at: 1, effectiveRange: &textRange)
        
        // "*"
        XCTAssertEqual(bulletRange.location, 0, "Incorrect list formatting")
        XCTAssertEqual(bulletRange.length, 1, "Incorrect list formatting")
        XCTAssertEqual(bulletAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(bulletAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect list formatting")
        
        // " Testing"
        XCTAssertEqual(textRange.location, 1, "Incorrect list formatting")
        XCTAssertEqual(textRange.length, 8, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect list formatting")
    }
    
    func testListSingleNumber() {
        let string = "# Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var numberRange = NSRange(location: 0, length: 0)
        let numberAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &numberRange)
        
        var textRange = NSRange(location: 0, length: 0)
        let textAttributes = mutAttributedString.attributes(at: 1, effectiveRange: &textRange)
        
        // "*"
        XCTAssertEqual(numberRange.location, 0, "Incorrect list formatting")
        XCTAssertEqual(numberRange.length, 1, "Incorrect list formatting")
        XCTAssertEqual(numberAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(numberAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect list formatting")
        
        // " Testing"
        XCTAssertEqual(textRange.location, 1, "Incorrect list formatting")
        XCTAssertEqual(textRange.length, 8, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect list formatting")
    }
    
    func testListMultipleBulletNoSpace() {
        let string = "***Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var bulletRange = NSRange(location: 0, length: 0)
        let bulletAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &bulletRange)
        
        var textRange = NSRange(location: 0, length: 0)
        let textAttributes = mutAttributedString.attributes(at: 3, effectiveRange: &textRange)
        
        // "*"
        XCTAssertEqual(bulletRange.location, 0, "Incorrect list formatting")
        XCTAssertEqual(bulletRange.length, 3, "Incorrect list formatting")
        XCTAssertEqual(bulletAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(bulletAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect list formatting")
        
        // " Testing"
        XCTAssertEqual(textRange.location, 3, "Incorrect list formatting")
        XCTAssertEqual(textRange.length, 7, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect list formatting")
    }
    
    func testListMultipleNumberNoSpace() {
        let string = "###Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var numberRange = NSRange(location: 0, length: 0)
        let numberAttributes = mutAttributedString.attributes(at: 0, effectiveRange: &numberRange)
        
        var textRange = NSRange(location: 0, length: 0)
        let textAttributes = mutAttributedString.attributes(at: 3, effectiveRange: &textRange)
        
        // "*"
        XCTAssertEqual(numberRange.location, 0, "Incorrect list formatting")
        XCTAssertEqual(numberRange.length, 3, "Incorrect list formatting")
        XCTAssertEqual(numberAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(numberAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect list formatting")
        
        // " Testing"
        XCTAssertEqual(textRange.location, 3, "Incorrect list formatting")
        XCTAssertEqual(textRange.length, 7, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect list formatting")
        XCTAssertEqual(textAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect list formatting")
    }
    
    func testOpenAndClosingReference() {
        let string = "Testing.<ref>{{cite web | url=https://en.wikipedia.org}}</ref> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var refOpenRange = NSRange(location: 0, length: 0)
        let refOpenAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &refOpenRange)

        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 13, effectiveRange: &templateRange)
        
        var refCloseRange = NSRange(location: 0, length: 0)
        let refCloseAttributes = mutAttributedString.attributes(at: 56, effectiveRange: &refCloseRange)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 62, effectiveRange: &base2Range)
        
        // "Testing."
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "<ref>"
        XCTAssertEqual(refOpenRange.location, 8, "Incorrect template formatting")
        XCTAssertEqual(refOpenRange.length, 5, "Incorrect template formatting")
        XCTAssertEqual(refOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(refOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect template formatting")
        
        // "{{cite web | url=https://en.wikipedia.org}}"
        XCTAssertEqual(templateRange.location, 13, "Incorrect base formatting")
        XCTAssertEqual(templateRange.length, 43, "Incorrect base formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect base formatting")
        
        // "</ref>"
        XCTAssertEqual(refCloseRange.location, 56, "Incorrect base formatting")
        XCTAssertEqual(refCloseRange.length, 6, "Incorrect base formatting")
        XCTAssertEqual(refCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(refCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect base formatting")
        
        // " Testing"
        XCTAssertEqual(base2Range.location, 62, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testOpenAndClosingReferenceWithName() {
        let string = "Testing.<ref name=\"test\">{{cite web | url=https://en.wikipedia.org}}</ref> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var refOpenRange = NSRange(location: 0, length: 0)
        let refOpenAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &refOpenRange)

        var templateRange = NSRange(location: 0, length: 0)
        let templateAttributes = mutAttributedString.attributes(at: 25, effectiveRange: &templateRange)
        
        var refCloseRange = NSRange(location: 0, length: 0)
        let refCloseAttributes = mutAttributedString.attributes(at: 68, effectiveRange: &refCloseRange)
        
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 74, effectiveRange: &base2Range)
        
        // "Testing."
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "<ref name="test">"
        XCTAssertEqual(refOpenRange.location, 8, "Incorrect reference formatting")
        XCTAssertEqual(refOpenRange.length, 17, "Incorrect reference formatting")
        XCTAssertEqual(refOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect reference formatting")
        XCTAssertEqual(refOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect template formatting")
        
        // "{{cite web | url=https://en.wikipedia.org}}"
        XCTAssertEqual(templateRange.location, 25, "Incorrect template formatting")
        XCTAssertEqual(templateRange.length, 43, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect template formatting")
        XCTAssertEqual(templateAttributes[.foregroundColor] as! UIColor, colors.purpleForegroundColor, "Incorrect base formatting")
        
        // "</ref>"
        XCTAssertEqual(refCloseRange.location, 68, "Incorrect reference formatting")
        XCTAssertEqual(refCloseRange.length, 6, "Incorrect reference formatting")
        XCTAssertEqual(refCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect reference formatting")
        XCTAssertEqual(refCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect base formatting")
        
        // " Testing"
        XCTAssertEqual(base2Range.location, 74, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testEmptyReference() {
        let string = "Testing.<ref name=\"test\" /> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var refRange = NSRange(location: 0, length: 0)
        let refAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &refRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 27, effectiveRange: &base2Range)
        
        // "Testing."
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "<ref name=\"test\" />"
        XCTAssertEqual(refRange.location, 8, "Incorrect reference formatting")
        XCTAssertEqual(refRange.length, 19, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect reference formatting")
        
        // " Testing"
        XCTAssertEqual(base2Range.location, 27, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testOpenOnlyReference() {
        let string = "Testing.<ref> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var refRange = NSRange(location: 0, length: 0)
        let refAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &refRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 13, effectiveRange: &base2Range)
        
        // "Testing."
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "<ref>"
        XCTAssertEqual(refRange.location, 8, "Incorrect reference formatting")
        XCTAssertEqual(refRange.length, 5, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect reference formatting")
        
        // " Testing"
        XCTAssertEqual(base2Range.location, 13, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testCloseOnlyReference() {
        let string = "Testing.</ref> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }
        
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)
        
        var refRange = NSRange(location: 0, length: 0)
        let refAttributes = mutAttributedString.attributes(at: 8, effectiveRange: &refRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 14, effectiveRange: &base2Range)
        
        // "Testing."
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // "</ref>"
        XCTAssertEqual(refRange.location, 8, "Incorrect reference formatting")
        XCTAssertEqual(refRange.length, 6, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect reference formatting")
        XCTAssertEqual(refAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect reference formatting")
        
        // " Testing"
        XCTAssertEqual(base2Range.location, 14, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testStrikethrough() {
            let string = "Testing. <s>Strikethrough.</s> Testing"
            let mutAttributedString = NSMutableAttributedString(string: string)

            for formatter in formatters {
                formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
            }

            var base1Range = NSRange(location: 0, length: 0)
            let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

            var strikethroughOpenRange = NSRange(location: 0, length: 0)
            let strikethroughOpenAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &strikethroughOpenRange)

            var strikethroughContentRange = NSRange(location: 0, length: 0)
            let strikethroughContentAttributes = mutAttributedString.attributes(at: 12, effectiveRange: &strikethroughContentRange)

            var strikethroughCloseRange = NSRange(location: 0, length: 0)
            let strikethroughCloseAttributes = mutAttributedString.attributes(at: 26, effectiveRange: &strikethroughCloseRange)

            var base2Range = NSRange(location: 0, length: 0)
            let base2Attributes = mutAttributedString.attributes(at: 32, effectiveRange: &base2Range)

            // "Testing. "
            XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
            XCTAssertEqual(base1Range.length, 9, "Incorrect base formatting")
            XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
            XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

            // "<s>"
            XCTAssertEqual(strikethroughOpenRange.location, 9, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughOpenRange.length, 3, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect strikethrough formatting")

            // "Strikethrough."
            XCTAssertEqual(strikethroughContentRange.location, 12, "Incorrect content formatting")
            XCTAssertEqual(strikethroughContentRange.length, 14, "Incorrect content formatting")
            XCTAssertEqual(strikethroughContentAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect content formatting")
            XCTAssertEqual(strikethroughContentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect content formatting")

            // "</s>"
            XCTAssertEqual(strikethroughCloseRange.location, 26, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughCloseRange.length, 4, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect strikethrough formatting")
            XCTAssertEqual(strikethroughCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect strikethrough formatting")

            // " Testing"
            XCTAssertEqual(base2Range.location, 30, "Incorrect base formatting")
            XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
            XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
            XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        }
}
