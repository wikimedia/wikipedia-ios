import Foundation
import UIKit
import ComponentsObjC

/// This class facilitates communication between WKSourceEditorView and the underlying TextKit (1 and 2) frameworks.
///

fileprivate var needsTextKit2: Bool {
    if #available(iOS 17, *) {
        return true
    } else {
        return false
    }
}

final class WKSourceEditorTextFrameworkMediator {
    
    let textView: UITextView
    let textKit1Storage: WKSourceEditorTextStorage?
    
    init() {
        
        let textView: UITextView
        
        if needsTextKit2 {
            // TODO: textkit 2 implementation
            textView = UITextView()
            textKit1Storage = nil
        } else {
            textKit1Storage = WKSourceEditorTextStorage(colors: Self.generateSourceEditorColors(), fonts: Self.generateSourceEditorFonts())
            let layoutManager = NSLayoutManager()
            let container = NSTextContainer()

            container.widthTracksTextView = true

            layoutManager.addTextContainer(container)
            textKit1Storage?.addLayoutManager(layoutManager)

            textView = UITextView(frame: .zero, textContainer: container)
        }
        
        textView.textContainerInset = .init(top: 16, left: 8, bottom: 16, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardDismissMode = .interactive
        
        self.textView = textView
    }
    
    // MARK: Internal
    
    func updateColorsAndFonts() {
        let newSourceEditorColors = Self.generateSourceEditorColors()
        newSourceEditorColors.baseForegroundColor = WKAppEnvironment.current.theme.text

        let newSourceEditorFonts = Self.generateSourceEditorFonts()
        let traitCollection = UITraitCollection(preferredContentSizeCategory: WKAppEnvironment.current.articleAndEditorTextSize)
        newSourceEditorFonts.baseFont = WKFont.for(.body, compatibleWith: traitCollection)
        
        if needsTextKit2 {
            // TODO: textkit 2 implementation
        } else {
            textKit1Storage?.update(newSourceEditorColors, andFonts: newSourceEditorFonts)
        }
    }
    
    // MARK: Private
    
    private static func generateSourceEditorColors() -> WKSourceEditorColors {
        let colors = WKSourceEditorColors()
        colors.baseForegroundColor = WKAppEnvironment.current.theme.text
        return colors
    }
    
    private static func generateSourceEditorFonts() -> WKSourceEditorFonts {
        let fonts = WKSourceEditorFonts()
        let traitCollection = UITraitCollection(preferredContentSizeCategory: WKAppEnvironment.current.articleAndEditorTextSize)
        fonts.baseFont = WKFont.for(.body, compatibleWith: traitCollection)
        return fonts
    }
}
