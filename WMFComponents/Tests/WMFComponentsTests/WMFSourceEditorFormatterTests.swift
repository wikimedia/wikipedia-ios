import XCTest
@testable import WMFComponents
@testable import WMFComponentsObjC

final class WMFSourceEditorFormatterTests: XCTestCase {

    var colors: WMFSourceEditorColors!
    var fonts: WMFSourceEditorFonts!

    var baseFormatter: WMFSourceEditorFormatterBase!
    var boldItalicsFormatter: WMFSourceEditorFormatterBoldItalics!
    var templateFormatter: WMFSourceEditorFormatterTemplate!
    var referenceFormatter: WMFSourceEditorFormatterReference!
    var listFormatter: WMFSourceEditorFormatterList!
    var headingFormatter: WMFSourceEditorFormatterHeading!
    var strikethroughFormatter: WMFSourceEditorFormatterStrikethrough!
    var subscriptFormatter: WMFSourceEditorFormatterSubscript!
    var superscriptFormatter: WMFSourceEditorFormatterSuperscript!
    var underlineFormatter: WMFSourceEditorFormatterUnderline!
    var linkFormatter: WMFSourceEditorFormatterLink!
    var commentFormatter: WMFSourceEditorFormatterComment!
    var findAndReplaceFormatter: WMFSourceEditorFormatterFindAndReplace!
    var formatters: [WMFSourceEditorFormatter] {
        return [baseFormatter, templateFormatter, boldItalicsFormatter, referenceFormatter, listFormatter, headingFormatter, strikethroughFormatter, subscriptFormatter, superscriptFormatter, underlineFormatter, linkFormatter, commentFormatter, findAndReplaceFormatter]
    }

    override func setUpWithError() throws {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)

        self.colors = WMFSourceEditorColors()
        self.colors.baseForegroundColor = WMFTheme.light.text
        self.colors.orangeForegroundColor = WMFTheme.light.editorOrange
        self.colors.purpleForegroundColor = WMFTheme.light.editorPurple
        self.colors.greenForegroundColor = WMFTheme.light.editorGreen
        self.colors.blueForegroundColor = WMFTheme.light.editorBlue
        self.colors.grayForegroundColor = WMFTheme.light.editorGray
        self.colors.matchForegroundColor = WMFTheme.light.editorMatchForeground
        self.colors.matchBackgroundColor = WMFTheme.light.editorMatchBackground
        self.colors.selectedMatchBackgroundColor = WMFTheme.light.editorSelectedMatchBackground
        self.colors.replacedMatchBackgroundColor = WMFTheme.light.editorReplacedMatchBackground

        self.fonts = WMFSourceEditorFonts()
        self.fonts.baseFont = WMFFont.for(.callout, compatibleWith: traitCollection)
        self.fonts.boldFont = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        self.fonts.italicsFont = WMFFont.for(.italicCallout, compatibleWith: traitCollection)
        self.fonts.boldItalicsFont = WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection)
        self.fonts.headingFont = WMFFont.for(.editorHeading, compatibleWith: traitCollection)
        self.fonts.subheading1Font = WMFFont.for(.editorSubheading1, compatibleWith: traitCollection)
        self.fonts.subheading2Font = WMFFont.for(.editorSubheading2, compatibleWith: traitCollection)
        self.fonts.subheading3Font = WMFFont.for(.editorSubheading3, compatibleWith: traitCollection)
        self.fonts.subheading4Font = WMFFont.for(.editorSubheading4, compatibleWith: traitCollection)

        self.baseFormatter = WMFSourceEditorFormatterBase(colors: colors, fonts: fonts, textAlignment: .left)
        self.boldItalicsFormatter = WMFSourceEditorFormatterBoldItalics(colors: colors, fonts: fonts)
        self.templateFormatter = WMFSourceEditorFormatterTemplate(colors: colors, fonts: fonts)
        self.referenceFormatter = WMFSourceEditorFormatterReference(colors: colors, fonts: fonts)
        self.listFormatter = WMFSourceEditorFormatterList(colors: colors, fonts: fonts)
        self.headingFormatter = WMFSourceEditorFormatterHeading(colors: colors, fonts: fonts)
        self.strikethroughFormatter = WMFSourceEditorFormatterStrikethrough(colors: colors, fonts: fonts)
        self.subscriptFormatter = WMFSourceEditorFormatterSubscript(colors: colors, fonts: fonts)
        self.superscriptFormatter = WMFSourceEditorFormatterSuperscript(colors: colors, fonts: fonts)
        self.underlineFormatter = WMFSourceEditorFormatterUnderline(colors: colors, fonts: fonts)
        self.linkFormatter = WMFSourceEditorFormatterLink(colors: colors, fonts: fonts)
        self.commentFormatter = WMFSourceEditorFormatterComment(colors: colors, fonts: fonts)
        self.findAndReplaceFormatter = WMFSourceEditorFormatterFindAndReplace(colors: colors, fonts: fonts)
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

    func testSubscript() {
        let string = "Testing. <sub>Subscript.</sub> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }

        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

        var subscriptOpenRange = NSRange(location: 0, length: 0)
        let subscriptOpenAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &subscriptOpenRange)

        var subscriptContentRange = NSRange(location: 0, length: 0)
        let subscriptContentAttributes = mutAttributedString.attributes(at: 14, effectiveRange: &subscriptContentRange)

        var subscriptCloseRange = NSRange(location: 0, length: 0)
        let subscriptCloseAttributes = mutAttributedString.attributes(at: 24, effectiveRange: &subscriptCloseRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 30, effectiveRange: &base2Range)

        // "Testing. "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 9, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "<sub>"
        XCTAssertEqual(subscriptOpenRange.location, 9, "Incorrect subscript formatting")
        XCTAssertEqual(subscriptOpenRange.length, 5, "Incorrect subscript formatting")

        XCTAssertEqual(subscriptOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect subscript formatting")
        XCTAssertEqual(subscriptOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect subscript formatting")

        // "Subscript."
        XCTAssertEqual(subscriptContentRange.location, 14, "Incorrect content formatting")
        XCTAssertEqual(subscriptContentRange.length, 10, "Incorrect content formatting")
        XCTAssertEqual(subscriptContentAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect content formatting")
        XCTAssertEqual(subscriptContentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect content formatting")

        // "</sub>"
        XCTAssertEqual(subscriptCloseRange.location, 24, "Incorrect subscript formatting")
        XCTAssertEqual(subscriptCloseRange.length, 6, "Incorrect subscript formatting")
        XCTAssertEqual(subscriptCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect subscript formatting")
        XCTAssertEqual(subscriptCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect subscript formatting")

        // " Testing"
        XCTAssertEqual(base2Range.location, 30, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }

    func testSuperscript() {
        let string = "Testing. <sup>Superscript.</sup> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }

        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

        var superscriptOpenRange = NSRange(location: 0, length: 0)
        let superscriptOpenAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &superscriptOpenRange)

        var superscriptContentRange = NSRange(location: 0, length: 0)
        let superscriptContentAttributes = mutAttributedString.attributes(at: 14, effectiveRange: &superscriptContentRange)

        var superscriptCloseRange = NSRange(location: 0, length: 0)
        let superscriptCloseAttributes = mutAttributedString.attributes(at: 26, effectiveRange: &superscriptCloseRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 32, effectiveRange: &base2Range)

        // "Testing. "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 9, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "<sup>"
        XCTAssertEqual(superscriptOpenRange.location, 9, "Incorrect superscript formatting")
        XCTAssertEqual(superscriptOpenRange.length, 5, "Incorrect superscript formatting")

        XCTAssertEqual(superscriptOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect superscript formatting")
        XCTAssertEqual(superscriptOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect superscript formatting")

        // "Superscript."
        XCTAssertEqual(superscriptContentRange.location, 14, "Incorrect content formatting")
        XCTAssertEqual(superscriptContentRange.length, 12, "Incorrect content formatting")
        XCTAssertEqual(superscriptContentAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect content formatting")
        XCTAssertEqual(superscriptContentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect content formatting")

        // "</sup>"
        XCTAssertEqual(superscriptCloseRange.location, 26, "Incorrect superscript formatting")
        XCTAssertEqual(superscriptCloseRange.length, 6, "Incorrect superscript formatting")
        XCTAssertEqual(superscriptCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect superscript formatting")
        XCTAssertEqual(superscriptCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect superscript formatting")

        // " Testing"
        XCTAssertEqual(base2Range.location, 32, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }

    func testUnderline() {

        let string = "Testing. <u>Underline.</u> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }

        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

        var underlineOpenRange = NSRange(location: 0, length: 0)
        let underlineOpenAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &underlineOpenRange)

        var underlineContentRange = NSRange(location: 0, length: 0)
        let underlineContentAttributes = mutAttributedString.attributes(at: 12, effectiveRange: &underlineContentRange)

        var underlineCloseRange = NSRange(location: 0, length: 0)
        let underlineCloseAttributes = mutAttributedString.attributes(at: 22, effectiveRange: &underlineCloseRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 26, effectiveRange: &base2Range)

        // "Testing. "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 9, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "<u>"
        XCTAssertEqual(underlineOpenRange.location, 9, "Incorrect underline formatting")
        XCTAssertEqual(underlineOpenRange.length, 3, "Incorrect underline formatting")
        XCTAssertEqual(underlineOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect underline formatting")
        XCTAssertEqual(underlineOpenAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect underline formatting")

        // "Underline."
        XCTAssertEqual(underlineContentRange.location, 12, "Incorrect content formatting")
        XCTAssertEqual(underlineContentRange.length, 10, "Incorrect content formatting")
        XCTAssertEqual(underlineContentAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect content formatting")
        XCTAssertEqual(underlineContentAttributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect content formatting")

        // "</u>"
        XCTAssertEqual(underlineCloseRange.location, 22, "Incorrect underline formatting")
        XCTAssertEqual(underlineCloseRange.length, 4, "Incorrect underline formatting")
        XCTAssertEqual(underlineCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect underline formatting")
        XCTAssertEqual(underlineCloseAttributes[.foregroundColor] as! UIColor, colors.greenForegroundColor, "Incorrect underline formatting")

        // " Testing"
        XCTAssertEqual(base2Range.location, 26, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testComment() {
        let string = "Testing. <!--Comment--> Testing"
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
         formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }

        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

        var commentOpenRange = NSRange(location: 0, length: 0)
        let commentOpenAttributes = mutAttributedString.attributes(at: 9, effectiveRange: &commentOpenRange)

        var commentContentRange = NSRange(location: 0, length: 0)
        let commentContentAttributes = mutAttributedString.attributes(at: 13, effectiveRange: &commentContentRange)

        var commentCloseRange = NSRange(location: 0, length: 0)
        let commentCloseAttributes = mutAttributedString.attributes(at: 20, effectiveRange: &commentCloseRange)

        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 23, effectiveRange: &base2Range)

        // "Testing. "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 9, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "<!--"
        XCTAssertEqual(commentOpenRange.location, 9, "Incorrect comment formatting")
        XCTAssertEqual(commentOpenRange.length, 4, "Incorrect comment formatting")
        XCTAssertEqual(commentOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect comment formatting")
        XCTAssertEqual(commentOpenAttributes[.foregroundColor] as! UIColor, colors.grayForegroundColor, "Incorrect comment formatting")

        // "Comment"
        XCTAssertEqual(commentContentRange.location, 13, "Incorrect content formatting")
        XCTAssertEqual(commentContentRange.length, 7, "Incorrect content formatting")
        XCTAssertEqual(commentContentAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect content formatting")
        XCTAssertEqual(commentContentAttributes[.foregroundColor] as! UIColor, colors.grayForegroundColor, "Incorrect content formatting")

        // "-->"
        XCTAssertEqual(commentCloseRange.location, 20, "Incorrect comment formatting")
        XCTAssertEqual(commentCloseRange.length, 3, "Incorrect comment formatting")
        XCTAssertEqual(commentCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect comment formatting")
        XCTAssertEqual(commentCloseAttributes[.foregroundColor] as! UIColor, colors.grayForegroundColor, "Incorrect comment formatting")

        // " Testing"
        XCTAssertEqual(base2Range.location, 23, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 8, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
    }
    
    func testFind() {
        let string = "Find a '''word''' and highlight that word."
        let mutAttributedString = NSMutableAttributedString(string: string)

        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: mutAttributedString, in: NSRange(location: 0, length: string.count))
        }

        findAndReplaceFormatter.startMatchSession(withFullAttributedString: mutAttributedString, searchText: "word")
        findAndReplaceFormatter.highlightNextMatch(inFullAttributedString: mutAttributedString, afterRangeValue: nil)

        // "Find a "
        var base1Range = NSRange(location: 0, length: 0)
        let base1Attributes = mutAttributedString.attributes(at: 0, effectiveRange: &base1Range)

        // '''
        var boldOpenRange = NSRange(location: 0, length: 0)
        let boldOpenAttributes = mutAttributedString.attributes(at: 7, effectiveRange: &boldOpenRange)

        // word
        var match1Range = NSRange(location: 0, length: 0)
        var match1Attributes = mutAttributedString.attributes(at: 10, effectiveRange: &match1Range)

        // '''
        var boldCloseRange = NSRange(location: 0, length: 0)
        let boldCloseAttributes = mutAttributedString.attributes(at: 14, effectiveRange: &boldCloseRange)

        // " and highlight that "
        var base2Range = NSRange(location: 0, length: 0)
        let base2Attributes = mutAttributedString.attributes(at: 17, effectiveRange: &base2Range)

        // word
        var match2Range = NSRange(location: 0, length: 0)
        var match2Attributes = mutAttributedString.attributes(at: 37, effectiveRange: &match2Range)

        // "."
        var base3Range = NSRange(location: 0, length: 0)
        let base3Attributes = mutAttributedString.attributes(at: 41, effectiveRange: &base3Range)

        // "Find a "
        XCTAssertEqual(base1Range.location, 0, "Incorrect base formatting")
        XCTAssertEqual(base1Range.length, 7, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base1Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "'''"
        XCTAssertEqual(boldOpenRange.location, 7, "Incorrect bold formatting")
        XCTAssertEqual(boldOpenRange.length, 3, "Incorrect bold formatting")
        XCTAssertEqual(boldOpenAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold formatting")
        XCTAssertEqual(boldOpenAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold formatting")

        // "word"
        XCTAssertEqual(match1Range.location, 10, "Incorrect match formatting")
        XCTAssertEqual(match1Range.length, 4, "Incorrect match formatting")
        XCTAssertEqual(match1Attributes[.font] as! UIFont, fonts.boldFont, "Incorrect match formatting")
        XCTAssertEqual(match1Attributes[.foregroundColor] as! UIColor, colors.matchForegroundColor, "Incorrect bmatchase formatting")
        XCTAssertEqual(match1Attributes[.backgroundColor] as! UIColor, colors.selectedMatchBackgroundColor, "Incorrect match formatting")

        // "'''"
        XCTAssertEqual(boldCloseRange.location, 14, "Incorrect bold formatting")
        XCTAssertEqual(boldCloseRange.length, 3, "Incorrect bold formatting")
        XCTAssertEqual(boldCloseAttributes[.font] as! UIFont, fonts.baseFont, "Incorrect bold formatting")
        XCTAssertEqual(boldCloseAttributes[.foregroundColor] as! UIColor, colors.orangeForegroundColor, "Incorrect bold formatting")

        // " and highlight that "
        XCTAssertEqual(base2Range.location, 17, "Incorrect base formatting")
        XCTAssertEqual(base2Range.length, 20, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base2Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")

        // "word"
        XCTAssertEqual(match2Range.location, 37, "Incorrect match formatting")
        XCTAssertEqual(match2Range.length, 4, "Incorrect match formatting")
        XCTAssertEqual(match2Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect match formatting")
        XCTAssertEqual(match2Attributes[.foregroundColor] as! UIColor, colors.matchForegroundColor, "Incorrect bmatchase formatting")
        XCTAssertEqual(match2Attributes[.backgroundColor] as! UIColor, colors.matchBackgroundColor, "Incorrect match formatting")

        // "."
        XCTAssertEqual(base3Range.location, 41, "Incorrect base formatting")
        XCTAssertEqual(base3Range.length, 1, "Incorrect base formatting")
        XCTAssertEqual(base3Attributes[.font] as! UIFont, fonts.baseFont, "Incorrect base formatting")
        XCTAssertEqual(base3Attributes[.foregroundColor] as! UIColor, colors.baseForegroundColor, "Incorrect base formatting")
        
        // Check that selected background color has now switched to 2nd instance
        findAndReplaceFormatter.highlightNextMatch(inFullAttributedString: mutAttributedString, afterRangeValue: nil)
        match1Attributes = mutAttributedString.attributes(at: 10, effectiveRange: &match1Range)
        match2Attributes = mutAttributedString.attributes(at: 37, effectiveRange: &match2Range)

        XCTAssertEqual(match1Attributes[.foregroundColor] as! UIColor, colors.matchForegroundColor, "Incorrect match formatting")
        XCTAssertEqual(match1Attributes[.backgroundColor] as! UIColor, colors.matchBackgroundColor, "Incorrect match formatting")
        XCTAssertEqual(match2Attributes[.foregroundColor] as! UIColor, colors.matchForegroundColor, "Incorrect match formatting")
        XCTAssertEqual(match2Attributes[.backgroundColor] as! UIColor, colors.selectedMatchBackgroundColor, "Incorrect match formatting")
    }
}
