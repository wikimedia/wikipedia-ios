import Foundation
import UIKit
import ComponentsObjC

/// This class facilitates communication between WKSourceEditorView and the underlying TextKit (1 and 2) frameworks, so that WKSourceEditorView is unaware of which framework is used.
/// When we need to drop TextKit 1, the goal is for all the adjustments to be in this one class

fileprivate var needsTextKit2: Bool {
    if #available(iOS 17, *) {
        return true
    } else {
        return false
    }
}

final class WKSourceEditorTextFrameworkMediator: NSObject {
    
    let textView: UITextView
    let textKit1Storage: WKSourceEditorTextStorage?
    let textKit2Storage: NSTextContentStorage?
    
    override init() {

        let textView: UITextView
        if needsTextKit2 {
            if #available(iOS 16, *) {
                textView = UITextView(usingTextLayoutManager: true)
                textKit2Storage = textView.textLayoutManager?.textContentManager as? NSTextContentStorage
            } else {
                fatalError("iOS 15 cannot handle TextKit2")
            }
            textKit1Storage = nil
        } else {
            textKit1Storage = WKSourceEditorTextStorage()
            
            let layoutManager = NSLayoutManager()
            let container = NSTextContainer()

            container.widthTracksTextView = true

            layoutManager.addTextContainer(container)
            textKit1Storage?.addLayoutManager(layoutManager)

            textView = UITextView(frame: .zero, textContainer: container)
            textKit2Storage = nil
        }
        
        self.textView = textView
        
        textView.textContainerInset = .init(top: 16, left: 8, bottom: 16, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardDismissMode = .interactive
        
        super.init()
        
        if needsTextKit2 {
            textKit2Storage?.delegate = self
        } else {
            textKit1Storage?.storageDelegate = self
        }
    }
    
    // MARK: Internal
    
    private var programmaticallyAddedSpace: Bool = false
    func updateColorsAndFonts() {
        if needsTextKit2 {
            
            // HACK: Reassign to retrigger NSTextContentStorageDelegate method
            // TODO: This is gross! See if there's a better way to increase editor font size.
            
            if let oldAttributedText = textView.attributedText {
                let newAttributedText = programmaticallyAddedSpace ? oldAttributedText.string.dropLast() : oldAttributedText.string + " "
                textView.attributedText = NSAttributedString(string: String(newAttributedText))
            }
            
        } else {
            textKit1Storage?.updateColorsAndFonts()
        }
    }
}

extension WKSourceEditorTextFrameworkMediator: WKSourceEditorStorageDelegate {
    var formatters: [WKSourceEditorFormatter] {
        return [WKSourceEditorFormatterBase(colors: colors, fonts: fonts)]
    }
    
    var colors: WKSourceEditorColors {
        let colors = WKSourceEditorColors()
        colors.baseForegroundColor = WKAppEnvironment.current.theme.text
        return colors
    }
    
    var fonts: WKSourceEditorFonts {
        let fonts = WKSourceEditorFonts()
        let traitCollection = UITraitCollection(preferredContentSizeCategory: WKAppEnvironment.current.articleAndEditorTextSize)
        fonts.baseFont = WKFont.for(.body, compatibleWith: traitCollection)
        return fonts
    }
}

 extension WKSourceEditorTextFrameworkMediator: NSTextContentStorageDelegate {

    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        
        guard needsTextKit2 else {
            return nil
        }
        
        guard let originalText = textContentStorage.textStorage?.attributedSubstring(from: range),
              originalText.length > 0 else {
            return nil
        }
        let attributedString = NSMutableAttributedString(attributedString: originalText)

        let paragraphRange = NSRange(location: 0, length: originalText.length)
        attributedString.removeAttribute(.font, range: paragraphRange)
        attributedString.removeAttribute(.foregroundColor, range: paragraphRange)

        for formatter in formatters {
            formatter.update(colors, in: attributedString, in: paragraphRange)
            formatter.update(fonts, in: attributedString, in: paragraphRange)
        }
        
        return NSTextParagraph(attributedString: attributedString)
    }
 }
