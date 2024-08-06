import XCTest
@testable import WMFComponents

final class WMFSourceEditorTextFrameworkMediatorTests: XCTestCase {
    
    let mediator = {
        let viewModel = WMFSourceEditorViewModel(configuration: .full, initialText: "", localizedStrings: WMFSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left, needsReadOnly: false, onloadSelectRange: nil)
        let mediator = WMFSourceEditorTextFrameworkMediator(viewModel: viewModel)
        mediator.updateColorsAndFonts()
        return mediator
    }()
    
    func testBoldItalicsButtonSelectionState() throws {
        
        let text = "One\nTwo '''Three ''Four'' Five''' Six ''Seven'' Eight\nNine"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "One"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 3))
        XCTAssertFalse(selectionStates1.isBold)
        XCTAssertFalse(selectionStates1.isItalics)
        
        // "Two"
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 3))
        XCTAssertFalse(selectionStates2.isBold)
        XCTAssertFalse(selectionStates2.isItalics)
        
        // "Three"
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 11, length: 5))
        XCTAssertTrue(selectionStates3.isBold)
        XCTAssertFalse(selectionStates3.isItalics)
        
        // "Four"
        let selectionStates4 = mediator.selectionState(selectedDocumentRange: NSRange(location: 19, length: 4))
        XCTAssertTrue(selectionStates4.isBold)
        XCTAssertTrue(selectionStates4.isItalics)
        
        // "Five"
        let selectionStates5 = mediator.selectionState(selectedDocumentRange: NSRange(location: 26, length: 4))
        XCTAssertTrue(selectionStates5.isBold)
        XCTAssertFalse(selectionStates5.isItalics)
        
        // "Six"
        let selectionStates6 = mediator.selectionState(selectedDocumentRange: NSRange(location: 34, length: 3))
        XCTAssertFalse(selectionStates6.isBold)
        XCTAssertFalse(selectionStates6.isItalics)
        
        // "Seven"
        let selectionStates7 = mediator.selectionState(selectedDocumentRange: NSRange(location: 40, length: 5))
        XCTAssertFalse(selectionStates7.isBold)
        XCTAssertTrue(selectionStates7.isItalics)
        
        // "Eight"
        let selectionStates8 = mediator.selectionState(selectedDocumentRange: NSRange(location: 48, length: 5))
        XCTAssertFalse(selectionStates8.isBold)
        XCTAssertFalse(selectionStates8.isItalics)
        
        // "Nine"
        let selectionStates9 = mediator.selectionState(selectedDocumentRange: NSRange(location: 54, length: 4))
        XCTAssertFalse(selectionStates9.isBold)
        XCTAssertFalse(selectionStates9.isItalics)
    }
    
    func testSelectionSpanningNonFormattedState1() throws {
        let text = "Testing '''bold with {{template}}''' selection that spans nonbold."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "bold with {{template}}"
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 11, length: 22))
        XCTAssertTrue(selectionStates.isBold)
        XCTAssertFalse(selectionStates.isHorizontalTemplate)
    }
    
    func testSelectionSpanningNonFormattedState2() throws {
        let text = "Testing {{template | '''bold'''}} selection that spans nonbold."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "template | '''bold'''"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 10, length: 21))
        XCTAssertFalse(selectionStates1.isBold)
        XCTAssertTrue(selectionStates1.isHorizontalTemplate)
    }
    func testClosingBoldSelectionStateCursor() throws {
        let text = "One '''Two''' Three"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 10, length: 0))
        XCTAssertTrue(selectionStates.isBold)
    }
    
    func testClosingItalicsSelectionStateCursor() throws {
        let text = "One ''Two'' Three"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 9, length: 0))
        XCTAssertTrue(selectionStates.isItalics)
    }
    
    func testHorizontalTemplateButtonSelectionStateCursor() throws {
        let text = "Testing simple {{Currentdate}} template example."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "Testing"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 0))
        XCTAssertFalse(selectionStates1.isHorizontalTemplate)
        
        // "Currentdate"
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 20, length: 0))
        XCTAssertTrue(selectionStates2.isHorizontalTemplate)
        
        // "template"
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 33, length: 0))
        XCTAssertFalse(selectionStates3.isHorizontalTemplate)
    }
    
    func testHorizontalTemplateButtonSelectionStateRange() throws {
        let text = "Testing simple {{Currentdate}} template example."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "Testing"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 3))
        XCTAssertFalse(selectionStates1.isHorizontalTemplate)
        
        // "Currentdate"
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 20, length: 3))
        XCTAssertTrue(selectionStates2.isHorizontalTemplate)
        
        // "template"
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 33, length: 3))
        XCTAssertFalse(selectionStates3.isHorizontalTemplate)
    }
    
    func testVerticalTemplateStartButtonSelectionStateCursor() throws {
        let text = "{{Infobox officeholder"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "Testing"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 0))
        XCTAssertFalse(selectionStates1.isHorizontalTemplate)
    }
    
    func testVerticalTemplateParameterButtonSelectionStateCursor() throws {
        let text = "| genus = Felis"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "Testing"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 0))
        XCTAssertFalse(selectionStates1.isHorizontalTemplate)
    }
    
    func testVerticalTemplateEndButtonSelectionStateCursor() throws {
        let text = "}}"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "Testing"
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 1, length: 0))
        XCTAssertFalse(selectionStates1.isHorizontalTemplate)
    }
    
    func testReferenceSelectionState() throws {
        let text = "Testing <ref>Testing</ref> Testing"
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 13, length: 7))
        XCTAssertTrue(selectionStates.isHorizontalReference)
    }
    
    func testReferenceSelectionStateCursor() throws {
        let text = "Testing <ref>Testing</ref> Testing"
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 16, length: 0))
        XCTAssertTrue(selectionStates.isHorizontalReference)
    }
    
    func testReferenceNamedSelectionState() throws {
        let text = "Testing <ref name=\"testing\">Testing</ref> Testing"
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 28, length: 7))
        XCTAssertTrue(selectionStates.isHorizontalReference)
    }
    
    func testReferenceNamedSelectionStateCursor() throws {
        let text = "Testing <ref name=\"testing\">Testing</ref> Testing"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 31, length: 0))
        XCTAssertTrue(selectionStates.isHorizontalReference)
    }
    
    func testListBulletSingleSelectionState() throws {
        
        let text = "* Test"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 2, length: 4))
        XCTAssertTrue(selectionStates.isBulletSingleList)
        XCTAssertFalse(selectionStates.isBulletMultipleList)
        XCTAssertFalse(selectionStates.isNumberSingleList)
        XCTAssertFalse(selectionStates.isNumberMultipleList)
    }
    
    func testListBulletMultipleSelectionState() throws {
        
        let text = "** Test"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 0))
        XCTAssertFalse(selectionStates.isBulletSingleList)
        XCTAssertTrue(selectionStates.isBulletMultipleList)
        XCTAssertFalse(selectionStates.isNumberSingleList)
        XCTAssertFalse(selectionStates.isNumberMultipleList)
    }
    
    func testListNumberSingleSelectionState() throws {
        
        let text = "# Test"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 2, length: 4))
        XCTAssertFalse(selectionStates.isBulletSingleList)
        XCTAssertFalse(selectionStates.isBulletMultipleList)
        XCTAssertTrue(selectionStates.isNumberSingleList)
        XCTAssertFalse(selectionStates.isNumberMultipleList)
    }
    
    func testListNumberMultipleSelectionState() throws {
        
        let text = "## Test"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 0))
        XCTAssertFalse(selectionStates.isBulletSingleList)
        XCTAssertFalse(selectionStates.isBulletMultipleList)
        XCTAssertFalse(selectionStates.isNumberSingleList)
        XCTAssertTrue(selectionStates.isNumberMultipleList)
    }
    
    func testHorizontalTemplateButtonSelectionStateFormattedRange() throws {
        let text = "Testing inner formatted {{cite web | url=https://en.wikipedia.org | title = The '''Free''' Encyclopedia}} template example."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        // "cite web | url=https://en.wikipedia.org | title = The '''Free''' Encyclopedia"
        let selectionStates = mediator.selectionState(selectedDocumentRange: NSRange(location: 26, length: 77))
        XCTAssertTrue(selectionStates.isHorizontalTemplate)
    }
    
    func testHeadingSelectionState() throws {
        
        let text = "== Test =="
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 4))
        XCTAssertTrue(selectionStates1.isHeading)
        XCTAssertFalse(selectionStates1.isSubheading1)
        XCTAssertFalse(selectionStates1.isSubheading2)
        XCTAssertFalse(selectionStates1.isSubheading3)
        XCTAssertFalse(selectionStates1.isSubheading4)
        
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 6, length: 0))
        XCTAssertTrue(selectionStates2.isHeading)
        XCTAssertFalse(selectionStates2.isSubheading1)
        XCTAssertFalse(selectionStates2.isSubheading2)
        XCTAssertFalse(selectionStates2.isSubheading3)
        XCTAssertFalse(selectionStates2.isSubheading4)
    }
    
    func testSubheading1SelectionState() throws {
        
        let text = "=== Test ==="
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 4, length: 4))
        XCTAssertFalse(selectionStates1.isHeading)
        XCTAssertTrue(selectionStates1.isSubheading1)
        XCTAssertFalse(selectionStates1.isSubheading2)
        XCTAssertFalse(selectionStates1.isSubheading3)
        XCTAssertFalse(selectionStates1.isSubheading4)
        
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 6, length: 0))
        XCTAssertFalse(selectionStates2.isHeading)
        XCTAssertTrue(selectionStates2.isSubheading1)
        XCTAssertFalse(selectionStates2.isSubheading2)
        XCTAssertFalse(selectionStates2.isSubheading3)
        XCTAssertFalse(selectionStates2.isSubheading4)
    }
    
    func testSubheading2SelectionState() throws {
        
        let text = "==== Test ===="
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 5, length: 4))
        XCTAssertFalse(selectionStates1.isHeading)
        XCTAssertFalse(selectionStates1.isSubheading1)
        XCTAssertTrue(selectionStates1.isSubheading2)
        XCTAssertFalse(selectionStates1.isSubheading3)
        XCTAssertFalse(selectionStates1.isSubheading4)
        
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 7, length: 0))
        XCTAssertFalse(selectionStates2.isHeading)
        XCTAssertFalse(selectionStates2.isSubheading1)
        XCTAssertTrue(selectionStates2.isSubheading2)
        XCTAssertFalse(selectionStates2.isSubheading3)
        XCTAssertFalse(selectionStates2.isSubheading4)
    }
    
    func testSubheading3SelectionState() throws {
        
        let text = "===== Test ====="
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 6, length: 4))
        XCTAssertFalse(selectionStates1.isHeading)
        XCTAssertFalse(selectionStates1.isSubheading1)
        XCTAssertFalse(selectionStates1.isSubheading2)
        XCTAssertTrue(selectionStates1.isSubheading3)
        XCTAssertFalse(selectionStates1.isSubheading4)
        
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 8, length: 0))
        XCTAssertFalse(selectionStates2.isHeading)
        XCTAssertFalse(selectionStates2.isSubheading1)
        XCTAssertFalse(selectionStates2.isSubheading2)
        XCTAssertTrue(selectionStates2.isSubheading3)
        XCTAssertFalse(selectionStates2.isSubheading4)
    }
    
    func testSubheading4SelectionState() throws {
        
        let text = "====== Test ======"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 7, length: 4))
        XCTAssertFalse(selectionStates1.isHeading)
        XCTAssertFalse(selectionStates1.isSubheading1)
        XCTAssertFalse(selectionStates1.isSubheading2)
        XCTAssertFalse(selectionStates1.isSubheading3)
        XCTAssertTrue(selectionStates1.isSubheading4)
        
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 9, length: 0))
        XCTAssertFalse(selectionStates2.isHeading)
        XCTAssertFalse(selectionStates2.isSubheading1)
        XCTAssertFalse(selectionStates2.isSubheading2)
        XCTAssertFalse(selectionStates2.isSubheading3)
        XCTAssertTrue(selectionStates2.isSubheading4)
    }
    
    func testStrikethroughSelectionState() throws {
        let text = "Testing <s>Strikethrough</s> Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 7))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 11, length: 13))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 29, length: 7))
        XCTAssertFalse(selectionStates1.isStrikethrough)
        XCTAssertTrue(selectionStates2.isStrikethrough)
        XCTAssertFalse(selectionStates3.isStrikethrough)
    }
    
    func testStrikethroughSelectionStateCursor() throws {
        let text = "Testing <s>Strikethrough</s> Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 0))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 17, length: 0))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 33, length: 0))
        XCTAssertFalse(selectionStates1.isStrikethrough)
        XCTAssertTrue(selectionStates2.isStrikethrough)
        XCTAssertFalse(selectionStates3.isStrikethrough)
    }
    
    func testLinkState() throws {
        let text = "Testing [[Link with space]] Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 7))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 10, length: 15))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 28, length: 7))
        XCTAssertFalse(selectionStates1.isSimpleLink)
        XCTAssertFalse(selectionStates1.isLinkWithNestedLink)
        
        XCTAssertTrue(selectionStates2.isSimpleLink)
        XCTAssertFalse(selectionStates3.isLinkWithNestedLink)
        
        XCTAssertFalse(selectionStates3.isSimpleLink)
        XCTAssertFalse(selectionStates3.isLinkWithNestedLink)
    }
    
    func testLinkCursorState() throws {
        let text = "Testing [[Link with space]] Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 0))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 12, length: 0))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 30, length: 0))
        XCTAssertFalse(selectionStates1.isSimpleLink)
        XCTAssertFalse(selectionStates1.isLinkWithNestedLink)
        
        XCTAssertTrue(selectionStates2.isSimpleLink)
        XCTAssertFalse(selectionStates2.isLinkWithNestedLink)
        
        XCTAssertFalse(selectionStates3.isSimpleLink)
        XCTAssertFalse(selectionStates3.isLinkWithNestedLink)
    }
    
    func testNestedLinkState() throws {
        let text = "Test [[File:Cat with fish.jpg|thumb|left|Cat with [[fish]]|alt=Photo of cat looking at fish]] Test"
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 4))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 12, length: 3))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 52, length: 3))
        let selectionStates4 = mediator.selectionState(selectedDocumentRange: NSRange(location: 72, length: 3))
        let selectionStates5 = mediator.selectionState(selectedDocumentRange: NSRange(location: 94, length: 4))
        
        // "Test"
        XCTAssertFalse(selectionStates1.isSimpleLink)
        XCTAssertFalse(selectionStates1.isLinkWithNestedLink)
        
        // "Cat"
        XCTAssertFalse(selectionStates2.isSimpleLink)
        XCTAssertTrue(selectionStates2.isLinkWithNestedLink)
        
        // "fish"
        XCTAssertTrue(selectionStates3.isSimpleLink)
        XCTAssertTrue(selectionStates3.isLinkWithNestedLink)
        
        // "cat"
        XCTAssertFalse(selectionStates4.isSimpleLink)
        XCTAssertTrue(selectionStates4.isLinkWithNestedLink)
        
        // "Test"
        XCTAssertFalse(selectionStates5.isSimpleLink)
        XCTAssertFalse(selectionStates5.isLinkWithNestedLink)
    }
    
    func testNestedLinkStateCursor() throws {
        let text = "Test [[File:Cat with fish.jpg|thumb|left|Cat with [[fish]]|alt=Photo of cat looking at fish]] Test"
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 0))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 13, length: 0))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 54, length: 0))
        let selectionStates4 = mediator.selectionState(selectedDocumentRange: NSRange(location: 73, length: 0))
        let selectionStates5 = mediator.selectionState(selectedDocumentRange: NSRange(location: 96, length: 0))
        
        // "Test"
        XCTAssertFalse(selectionStates1.isSimpleLink)
        XCTAssertFalse(selectionStates1.isLinkWithNestedLink)
        
        // "Cat"
        XCTAssertFalse(selectionStates2.isSimpleLink)
        XCTAssertTrue(selectionStates2.isLinkWithNestedLink)
        
        // "fish"
        XCTAssertTrue(selectionStates3.isSimpleLink)
        XCTAssertTrue(selectionStates3.isLinkWithNestedLink)
        
        // "cat"
        XCTAssertFalse(selectionStates4.isSimpleLink)
        XCTAssertTrue(selectionStates4.isLinkWithNestedLink)
        
        // "Test"
        XCTAssertFalse(selectionStates5.isSimpleLink)
        XCTAssertFalse(selectionStates5.isLinkWithNestedLink)
    }
    
    func testCommentSelectionState() throws {
        let text = "Testing <!--Comment--> Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)

        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 0, length: 7))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 12, length: 7))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 23, length: 7))
        XCTAssertFalse(selectionStates1.isComment)
        XCTAssertTrue(selectionStates2.isComment)
        XCTAssertFalse(selectionStates3.isComment)
    }

    func testCommentSelectionStateCursor() throws {
        let text = "Testing <!--Comment--> Testing."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        let selectionStates1 = mediator.selectionState(selectedDocumentRange: NSRange(location: 3, length: 0))
        let selectionStates2 = mediator.selectionState(selectedDocumentRange: NSRange(location: 19, length: 0))
        let selectionStates3 = mediator.selectionState(selectedDocumentRange: NSRange(location: 25, length: 0))
        XCTAssertFalse(selectionStates1.isComment)
        XCTAssertTrue(selectionStates2.isComment)
        XCTAssertFalse(selectionStates3.isComment)
    }
    
    func testFindWithResults() throws {
        let text = "Find a '''word''' and highlight that word."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        mediator.findStart(text: "word")
        guard let formatter = mediator.findAndReplaceFormatter else {
            XCTFail("Missing find formatter.")
            return
        }
        
        XCTAssertEqual(formatter.selectedMatchIndex, 0, "Find - Incorrect selected match index")
        XCTAssertEqual(formatter.matchCount, 2, "Find - Incorrect match count")
    }
    
    func testFindWithoutResults() throws {
        let text = "Find a '''word''' and highlight that word."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        mediator.findStart(text: "cat")
        guard let formatter = mediator.findAndReplaceFormatter else {
            XCTFail("Missing find formatter.")
            return
        }
        
        XCTAssertEqual(formatter.selectedMatchIndex, NSNotFound, "Find - Incorrect selected match index")
        XCTAssertEqual(formatter.matchCount, 0, "Find - Incorrect match count")
    }
    
    func testReplaceSingle() throws {
        let text = "Find a '''word''' and replace that word."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        mediator.findStart(text: "word")
        guard let formatter = mediator.findAndReplaceFormatter else {
            XCTFail("Missing find formatter.")
            return
        }
        
        mediator.replaceSingle(replaceText: "testing")
        XCTAssertEqual(mediator.textView.attributedText.string, "Find a '''testing''' and replace that word.", "Replace single failure")
        
        XCTAssertEqual(formatter.selectedMatchIndex, 0, "Replace single - Incorrect selected match index")
        XCTAssertEqual(formatter.matchCount, 1, "Replace single - Incorrect match count")
    }
    
    func testReplaceAll() throws {
        let text = "Find a '''word''' and replace that word."
        mediator.textView.attributedText = NSAttributedString(string: text)
        
        mediator.findStart(text: "word")
        guard let formatter = mediator.findAndReplaceFormatter else {
            XCTFail("Missing find formatter.")
            return
        }
        
        mediator.replaceAll(replaceText: "testing")
        XCTAssertEqual(mediator.textView.attributedText.string, "Find a '''testing''' and replace that testing.", "Replace all failure")
        
        XCTAssertEqual(formatter.selectedMatchIndex, NSNotFound, "Replace all - Incorrect selected match index")
        XCTAssertEqual(formatter.matchCount, 0, "Replace all - Incorrect match count")
    }
}
