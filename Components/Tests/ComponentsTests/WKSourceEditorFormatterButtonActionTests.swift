import XCTest
@testable import Components

final class WKSourceEditorFormatterButtonActionTests: XCTestCase {
    
    let mediator = {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "", localizedStrings: WKSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left)
        let mediator = WKSourceEditorTextFrameworkMediator(viewModel: viewModel)
        mediator.updateColorsAndFonts()
        return mediator
    }()

    func testBoldInsert() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 3)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''Two''' Three Four")
    }
    
    func testBoldRemove() throws {
        let text = "One '''Two''' Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 7, length: 3)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testItalicsInsert() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 8, length: 5)
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two ''Three'' Four")
    }
    
    func testItalicsRemove() throws {
        let text = "One Two '''Three''' Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 11, length: 5)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testCursorBoldRemove() throws {
        let text = "One '''Two''' Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 8, length: 0) // Just a cursor inside Two
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testCursorItalicsRemove() throws {
        let text = "One Two '''Three''' Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 14, length: 0)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView) // Just a cursor inside Three
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testBoldItalicsInsert() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 3)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .add, in: mediator.textView)
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''''Two''''' Three Four")
    }
    
    func testBoldItalicsRemove() throws {
        let text = "One '''''Two''''' Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 9, length: 3)
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One ''Two'' Three Four")
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testCursorBoldInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One ''' '''Two Three Four")
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testCursorItalicsInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '' ''Two Three Four")
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testBoldInnerRemoveAndInsert() throws {
        let text = "One '''Two Three Four''' Five"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 11, length: 5) // Selected Three
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''Two '''Three''' Four''' Five")
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''Two Three Four''' Five")
    }
    
    func testItalicsInnerRemoveAndInsert() throws {
        let text = "One ''Two Three Four'' Five"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 10, length: 5) // Selected Three
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One ''Two ''Three'' Four'' Five")
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One ''Two Three Four'' Five")
    }
    
    func testBoldItalicsInnerRemoveBoldAndInsert() throws {
        let text = "One '''''Two Three Four''''' Five"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 13, length: 5) // Selected Three
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''''Two '''Three''' Four''''' Five")
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''''Two Three Four''''' Five")
    }
    
    func testBoldItalicsInnerRemoveItalicsAndInsert() throws {
        let text = "One '''''Two Three Four''''' Five"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 13, length: 5) // Selected Three
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''''Two ''Three'' Four''''' Five")
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '''''Two Three Four''''' Five")
    }
    
    func testTemplateInsert() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 3)
        mediator.templateFormatter?.toggleTemplateFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One {{Two}} Three Four")
    }
    
    func testTemplateRemove() throws {
        let text = "One {{Two}} Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 6, length: 3)
        mediator.templateFormatter?.toggleTemplateFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testCursorTemplateInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.templateFormatter?.toggleTemplateFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One {{ }}Two Three Four")
        mediator.templateFormatter?.toggleTemplateFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testStrikethroughInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length:3)
        mediator.strikethroughFormatter?.toggleStrikethroughFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One <s>Two</s> Three Four")
        mediator.strikethroughFormatter?.toggleStrikethroughFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
}
