// This Swift file was auto-generated from Objective-C.

import UIKit

class WMFSourceEditorTextStorage: NSTextStorage {

    private let backingStore = NSMutableAttributedString()

    weak var storageDelegate: WMFSourceEditorStorageDelegate?
    var syntaxHighlightProcessingEnabled = true

    // MARK: - Overrides

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {
        if syntaxHighlightProcessingEnabled {
            addSyntaxHighlighting(toEditedRange: editedRange)
        }
        super.processEditing()
    }

    // MARK: - Public

    func updateColorsAndFonts() {
        guard let storageDelegate else { return }

        let colors = storageDelegate.colors
        let fonts = storageDelegate.fonts

        beginEditing()
        let allRange = NSRange(location: 0, length: backingStore.length)
        for formatter in storageDelegate.formatters {
            formatter.update(colors, in: self, in: allRange)
            formatter.update(fonts, in: self, in: allRange)
        }
        endEditing()
    }

    // MARK: - Private

    private func addSyntaxHighlighting(toEditedRange editedRange: NSRange) {
        // Extend range to entire line for reevaluation, not just what was edited
        let nsString = backingStore.string as NSString
        var extendedRange = NSUnionRange(editedRange, nsString.lineRange(for: NSRange(location: editedRange.location, length: 0)))
        extendedRange = NSUnionRange(editedRange, nsString.lineRange(for: NSRange(location: NSMaxRange(editedRange), length: 0)))
        addSyntaxHighlighting(toExtendedRange: extendedRange)
    }

    private func addSyntaxHighlighting(toExtendedRange extendedRange: NSRange) {
        guard let storageDelegate else { return }
        for formatter in storageDelegate.formatters {
            formatter.addSyntaxHighlighting(to: self, in: extendedRange)
        }
    }
}
