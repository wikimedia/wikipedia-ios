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
    
    func testSingleBoldRemove() throws {
        let text = "One '''Two''' Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 8, length: 0) // Just a cursor inside Two
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testSingleItalicsRemove() throws {
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
    
    func testSingleBoldInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One ''' '''Two Three Four")
        mediator.boldItalicsFormatter?.toggleBoldFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testSingleItalicsInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One '' ''Two Three Four")
        mediator.boldItalicsFormatter?.toggleItalicsFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
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
    
    func testSingleTemplateInsertAndRemove() throws {
        let text = "One Two Three Four"
        mediator.textView.attributedText = NSAttributedString(string: text)
        mediator.textView.selectedRange = NSRange(location: 4, length: 0) // Just a cursor before Two
        mediator.templateFormatter?.toggleTemplateFormatting(action: .add, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One {{ }}Two Three Four")
        mediator.templateFormatter?.toggleTemplateFormatting(action: .remove, in: mediator.textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "One Two Three Four")
    }
    
    func testHeadingAdd() throws {
        let text = "Test"
        let selectedRange = NSRange(location: 0, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .heading, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "\n==Test==\n")
    }
    
    func testHeadingRemove() throws {
        let text = "==Test=="
        let selectedRange = NSRange(location: 2, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .paragraph, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "Test")
    }
    
    func testSubheading1Add() throws {
        let text = "Test"
        let selectedRange = NSRange(location: 0, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .subheading1, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "\n===Test===\n")
    }
    
    func testSubheading1Remove() throws {
        let text = "===Test==="
        let selectedRange = NSRange(location: 3, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .paragraph, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "Test")
    }
    
    func testSubheading2Add() throws {
        let text = "Test"
        let selectedRange = NSRange(location: 0, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .subheading2, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "\n====Test====\n")
    }
    
    func testSubheading2Remove() throws {
        let text = "====Test===="
        let selectedRange = NSRange(location: 4, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .paragraph, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "Test")
    }
    
    func testSubheading3Add() throws {
        let text = "Test"
        let selectedRange = NSRange(location: 0, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .subheading3, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "\n=====Test=====\n")
    }
    
    func testSubheading3Remove() throws {
        let text = "=====Test====="
        let selectedRange = NSRange(location: 5, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .paragraph, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "Test")
    }
    
    func testSubheading4Add() throws {
        let text = "Test"
        let selectedRange = NSRange(location: 0, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .subheading4, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "\n======Test======\n")
    }
    
    func testSubheading4Remove() throws {
        let text = "======Test======"
        let selectedRange = NSRange(location: 6, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .paragraph, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "Test")
    }
    
    func testHeadingSwitchToSubheading3() throws {
        let text = "==Test=="
        let selectedRange = NSRange(location: 2, length: 4)
        let textView = mediator.textView
        textView.attributedText = NSAttributedString(string: text)
        textView.selectedRange = selectedRange
        mediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: .subheading3, currentSelectionState: mediator.selectionState(selectedDocumentRange: selectedRange), textView: textView)
        XCTAssertEqual(mediator.textView.attributedText.string, "=====Test=====")
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
