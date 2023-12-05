import XCTest
@testable import Components

final class WKSourceEditorTextFrameworkMediatorTests: XCTestCase {
    
    let mediator = {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "", isSyntaxHighlightingEnabled: true, textAlignment: .left)
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
        mediator.textView.becomeFirstResponder()
        mediator.textView.selectedRange = NSRange(location: 11, length: 5)
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
}
