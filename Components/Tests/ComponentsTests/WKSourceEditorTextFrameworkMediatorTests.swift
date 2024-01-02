import XCTest
@testable import Components

final class WKSourceEditorTextFrameworkMediatorTests: XCTestCase {
    
    let mediator = {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "", localizedStrings: WKSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left)
        let mediator = WKSourceEditorTextFrameworkMediator(viewModel: viewModel)
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
}
