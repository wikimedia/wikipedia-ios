import UIKit

protocol NativeWikitextEditorDelegate: AnyObject {
    func wikitextViewDidChange(_ textView: UITextView)
    var dataStore: MWKDataStore { get }
    var pageURL: URL { get }
}

class NativeWikitextEditorViewController: UIViewController, Themeable {
    
    weak var delegate: NativeWikitextEditorDelegate?
    private let theme: Theme
    private var preselectedTextRange: UITextRange?
    
    private lazy var editorInputViewsController: EditorInputViewsController = {
        let inputViewsController = EditorInputViewsController(webView: nil, webMessagingController: nil, findAndReplaceDisplayDelegate: self)
        inputViewsController.delegate = self
        
        return inputViewsController
    }()
    
    private var editorView: NativeWikitextEditorView {
        return view as! NativeWikitextEditorView
    }
    
    init(delegate: NativeWikitextEditorDelegate, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
        
        super.init(nibName: nil, bundle: nil)
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIApplication.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIApplication.keyboardWillHideNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let editorView = NativeWikitextEditorView(theme: theme)
//        if #available(iOS 16.0, *) {
//            editorView.textView.textContentStorage?.delegate = self
//        }
        editorView.textView.delegate = self
        view = editorView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override var inputViewController: UIInputViewController? {
        return editorInputViewsController.inputViewController
    }
    
    // MARK: Public
    
    func setupInitialText(_ text: String) {
        
        guard self.editorView.textView.text.count == 0 else {
            assertionFailure("Initial text should only be set once.")
            return
        }
        
        self.editorView.textView.text = text
    }
    
    func undo() {
        editorView.textView.undoManager?.undo()
    }
    
    func redo() {
        editorView.textView.undoManager?.redo()
    }
    
    func setInputAccessoryView(_ inputAccessoryView: UIView?) {
        editorView.textView.inputAccessoryView = inputAccessoryView
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        updateInsets(keyboardHeight: 0)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = max(frame.height - view.safeAreaInsets.bottom, 0)
            updateInsets(keyboardHeight: keyboardHeight)
        }
    }

    private func updateInsets(keyboardHeight: CGFloat) {
        editorView.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        editorView.textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }
    
    func apply(theme: Theme) {
        editorInputViewsController.apply(theme: theme)
        editorView.apply(theme: theme)
    }
}

extension NativeWikitextEditorViewController: NSTextContentStorageDelegate {
    @available(iOS 15.0, *)
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        guard let originalText = textContentStorage.textStorage?.attributedSubstring(from: range),
              originalText.length > 0 else {
            return nil
        }
        let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
        textWithDisplayAttributes.addWikitextSyntaxFormatting(withSearch: NSRange(location: 0, length: originalText.length), fontSizeTraitCollection: traitCollection, needsColors: true, theme: theme)
        return NSTextParagraph(attributedString: textWithDisplayAttributes)
    }
}

extension NativeWikitextEditorViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        // pageEditorInputViewsController.textSelectionDidChange(isRangeSelected: textView.selectedTextRange?.isEmpty ?? false)
        // todo: tell delegate that textView has changed. It can determine it's own publish button states. (in the case of talk page new topic, title field and this text view > 0, in the case of article editor, just this field > 0
        // publishButton.isEnabled = bodyTextView.textStorage.length == 0 ? false : true
        // formattingToolbarView.undoButton.isEnabled = textView.undoManager?.canUndo ?? false
        // formattingToolbarView.redoButton.isEnabled = textView.undoManager?.canRedo ?? false
        delegate?.wikitextViewDidChange(textView)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {

        editorInputViewsController.textSelectionDidChange(isRangeSelected: textView.selectedRange.length > 0)
        
        let formattingValues = formattingValuesForSelectedTextRangeOrCursor()
        
        if formattingValues.isBold {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .bold))
        }
        
        if formattingValues.isItalic {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .italic))
        }
        
        if formattingValues.isLink {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .link))
        }
        
        if formattingValues.isImage {
            editorInputViewsController.disableButton(button: EditorButton(kind: .link))
        }
        
        if formattingValues.isImage {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .link))
        }
        
        if formattingValues.isTemplate {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .template))
        }
        
        if formattingValues.isReference {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .reference))
        }
        
        if formattingValues.isSuperscript {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .superscript))
        }
        
        if formattingValues.isSubscript {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .subscript))
        }
        
        if formattingValues.isUnderline {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .underline))
        }
        
        if formattingValues.isStrikethrough {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .strikethrough))
        }
        
        if formattingValues.isComment {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .comment))
        }
        
        if formattingValues.isListBullet {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .li(ordered: false)))
            // todo: why aren't indent buttons enabling?
        } else {
            editorInputViewsController.disableButton(button: EditorButton(kind: .increaseIndentDepth))
            editorInputViewsController.disableButton(button: EditorButton(kind: .decreaseIndentDepth))
        }
        
        if formattingValues.isListNumber {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .li(ordered: true)))
            // todo: why aren't indent buttons enabling?
        } else {
            editorInputViewsController.disableButton(button: EditorButton(kind: .increaseIndentDepth))
            editorInputViewsController.disableButton(button: EditorButton(kind: .decreaseIndentDepth))
        }
        
        if formattingValues.isH2 {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .heading(type: .heading)))
        }
        
        if formattingValues.isH3 {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .heading(type: .subheading1)))
        }
        
        if formattingValues.isH4 {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .heading(type: .subheading2)))
        }
        
        if formattingValues.isH5 {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .heading(type: .subheading3)))
        }
        
        if formattingValues.isH6 {
            editorInputViewsController.buttonSelectionDidChange(button: EditorButton(kind: .heading(type: .subheading4)))
        }
    }
}


extension NativeWikitextEditorViewController: EditorInputViewsControllerDelegate {
    func editorInputViewsControllerDidTapBold(_ editorInputViewsController: EditorInputViewsController) {
        let formattingString = "'''"
        let isBold = formattingValuesForSelectedTextRangeOrCursor().isBold
        addOrRemoveFormattingStringFromSelectedText(formattingString: formattingString, shouldAddFormatting: !isBold)
    }
    
    func editorInputViewsControllerDidTapItalic(_ editorInputViewsController: EditorInputViewsController) {
        let formattingString = "''"
        let isItalic = formattingValuesForSelectedTextRangeOrCursor().isItalic
        addOrRemoveFormattingStringFromSelectedText(formattingString: formattingString, shouldAddFormatting: !isItalic)
    }
    
    func editorInputViewsControllerDidTapTemplate(_ editorInputViewsController: EditorInputViewsController) {
        let isTemplate = formattingValuesForSelectedTextRangeOrCursor().isTemplate
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "{{", endingFormattingString: "}}", shouldAddFormatting: !isTemplate)
    }
    
    func editorInputViewsControllerDidTapReference(_ editorInputViewsController: EditorInputViewsController) {
        let isReference = formattingValuesForSelectedTextRangeOrCursor().isReference
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<ref>", endingFormattingString: "</ref>", shouldAddFormatting: !isReference)
    }
    
    func editorInputViewsControllerDidTapSuperscript(_ editorInputViewsController: EditorInputViewsController) {
        let isSuperscript = formattingValuesForSelectedTextRangeOrCursor().isSuperscript
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<sup>", endingFormattingString: "</sup>", shouldAddFormatting: !isSuperscript)
    }
    
    func editorInputViewsControllerDidTapSubscript(_ editorInputViewsController: EditorInputViewsController) {
        let isSubscript = formattingValuesForSelectedTextRangeOrCursor().isSubscript
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<sub>", endingFormattingString: "</sub>", shouldAddFormatting: !isSubscript)
    }
    
    func editorInputViewsControllerDidTapComment(_ editorInputViewsController: EditorInputViewsController) {
        let isComment = formattingValuesForSelectedTextRangeOrCursor().isComment
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<!--", endingFormattingString: "-->", shouldAddFormatting: !isComment)
    }
    
    func editorInputViewsControllerDidTapUnderline(_ editorInputViewsController: EditorInputViewsController) {
        let isUnderline = formattingValuesForSelectedTextRangeOrCursor().isUnderline
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<u>", endingFormattingString: "</u>", shouldAddFormatting: !isUnderline)
    }
    
    func editorInputViewsControllerDidTapStrikethrough(_ editorInputViewsController: EditorInputViewsController) {
        let isStrikethrough = formattingValuesForSelectedTextRangeOrCursor().isStrikethrough
        addOrRemoveFormattingStringFromSelectedText(startingFormattingString: "<s>", endingFormattingString: "</s>", shouldAddFormatting: !isStrikethrough)
    }
    
    func editorInputViewsControllerDidTapListBullet(_ editorInputViewsController: EditorInputViewsController) {
        let textView = editorView.textView
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        if formattingValuesForSelectedTextRangeOrCursor().isListBullet {
            var numBullets = 0
            for char in textView.textStorage.attributedSubstring(from: lineRange).string {
                if char == "*" {
                    numBullets += 1
                }
            }
            textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: numBullets), with: "")
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: -1*numBullets),
                let newEnd = textView.position(from: selectedRange.end, offset: -1*numBullets) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
            
        } else {
            textView.textStorage.insert(NSAttributedString(string: "*"), at: lineRange.location)
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: 1),
                let newEnd = textView.position(from: selectedRange.end, offset: 1) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
        }
        
        textViewDidChange(textView)
        textViewDidChangeSelection(textView)
    }
    
    func editorInputViewsControllerDidTapListNumber(_ editorInputViewsController: EditorInputViewsController) {
        let textView = editorView.textView
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        if formattingValuesForSelectedTextRangeOrCursor().isListNumber {
            var numNumbers = 0
            for char in textView.textStorage.attributedSubstring(from: lineRange).string {
                if char == "#" {
                    numNumbers += 1
                }
            }
            textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: numNumbers), with: "")
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: -1*numNumbers),
                let newEnd = textView.position(from: selectedRange.end, offset: -1*numNumbers) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
            
        } else {
            textView.textStorage.insert(NSAttributedString(string: "#"), at: lineRange.location)
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: 1),
                let newEnd = textView.position(from: selectedRange.end, offset: 1) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
        }
        
        textViewDidChange(textView)
        textViewDidChangeSelection(textView)
    }
    
    func editorInputViewsControllerDidTapIndent(_ editorInputViewsController: EditorInputViewsController) {
        let formattingValues = formattingValuesForSelectedTextRangeOrCursor()
        guard formattingValues.isListBullet || formattingValues.isListNumber else {
            assertionFailure("Button should have been disabled")
            return
        }
        
        let textView = editorView.textView
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        
        textView.textStorage.insert(NSAttributedString(string: "*"), at: lineRange.location)
        // reset cursor so it doesn't move
        if let selectedRange = textView.selectedTextRange {
            if let newStart = textView.position(from: selectedRange.start, offset: 1),
            let newEnd = textView.position(from: selectedRange.end, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
            }
        }
    }
    
    func editorInputViewsControllerDidTapUnindent(_ editorInputViewsController: EditorInputViewsController) {
        let formattingValues = formattingValuesForSelectedTextRangeOrCursor()
        guard formattingValues.isListBullet || formattingValues.isListNumber else {
            assertionFailure("Button should have been disabled")
            return
        }
        
        let textView = editorView.textView
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        
        textView.textStorage.insert(NSAttributedString(string: ""), at: lineRange.location)
        // reset cursor so it doesn't move
        if let selectedRange = textView.selectedTextRange {
            if let newStart = textView.position(from: selectedRange.start, offset: 1),
            let newEnd = textView.position(from: selectedRange.end, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
            }
        }
    }
    
    func editorInputViewsControllerDidTapHeading(_ editorInputViewsController: EditorInputViewsController, depth: Int) {
        
        let formattingValues = formattingValuesForSelectedTextRangeOrCursor()
        
        let isCurrentlyH2 = formattingValues.isH2
        let isCurrentlyH3 = formattingValues.isH3
        let isCurrentlyH4 = formattingValues.isH4
        let isCurrentlyH5 = formattingValues.isH5
        let isCurrentlyH6 = formattingValues.isH6
        
        let formattingToRemove: String?
        if isCurrentlyH2 && depth != 2 {
            formattingToRemove = "=="
        } else if isCurrentlyH3 && depth != 3 {
            formattingToRemove = "==="
        } else if isCurrentlyH4 && depth != 4 {
            formattingToRemove = "===="
        } else if isCurrentlyH5 && depth != 5 {
            formattingToRemove = "====="
        } else if isCurrentlyH6 && depth != 6 {
            formattingToRemove = "======"
        } else {
            formattingToRemove = nil
        }
        
        let formattingToAdd: String?
        if !isCurrentlyH2 && depth == 2 {
            formattingToAdd = "=="
        } else if !isCurrentlyH3 && depth == 3 {
            formattingToAdd = "==="
        } else if !isCurrentlyH4 && depth == 4 {
            formattingToAdd = "===="
        } else if !isCurrentlyH5 && depth == 5 {
            formattingToAdd = "====="
        } else if !isCurrentlyH6 && depth == 6 {
            formattingToAdd = "======"
        } else {
            formattingToAdd = nil
        }
        
        guard formattingToRemove != nil || formattingToAdd != nil else {
            return
        }
        
        if let formattingToRemove {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: formattingToRemove, endingFormattingString: formattingToRemove)
            if selectedRangeIsSurroundedByFormattingString(formattingString: formattingToRemove) {
                removeSurroundingFormattingStringFromSelectedRange(formattingString: formattingToRemove)
            }
        }
        
        if let formattingToAdd {
            addStringFormattingCharacters(formattingString: formattingToAdd)
        }
    }
    
    func editorInputViewsControllerDidChangeInputAccessoryView(_ editorInputViewsController: EditorInputViewsController, inputAccessoryView: UIView?) {
        editorView.textView.inputAccessoryView = inputAccessoryView
        editorView.textView.reloadInputViews()
    }
    
    func editorInputViewsControllerDidTapMediaInsert(_ editorInputViewsController: EditorInputViewsController) {
        guard let delegate,
              let range =  editorView.textView.selectedTextRange else {
            return
        }
        
        // Need to save this off for later when user returns from insert media view controller
        self.preselectedTextRange = range
        
        let insertMediaViewController = InsertMediaViewController(articleTitle: delegate.pageURL.wmf_title, siteURL: delegate.pageURL.wmf_site)
        insertMediaViewController.delegate = self
        insertMediaViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: insertMediaViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
    
    func editorInputViewsControllerDidTapLinkInsert(_ editorInputViewsController: EditorInputViewsController) {
        
        expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "[[", endingFormattingString: "]]")
        
        guard let linkInfo = extractLinkInfoFromSelectedRange(),
              let link = Link(page: linkInfo.linkText, label: linkInfo.labelText, exists: linkInfo.linkExists),
        let delegate = delegate else {
            return
        }

        guard link.exists,
              let editLinkViewController = EditLinkViewController(link: link, siteURL: delegate.pageURL.wmf_site, dataStore: delegate.dataStore) else {
                  
            let insertLinkViewController = InsertLinkViewController(link: link, siteURL: delegate.pageURL.wmf_site, dataStore: delegate.dataStore)
              insertLinkViewController.delegate = self
              let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
              present(navigationController, animated: true)
            return
        }
        
        editLinkViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
}

extension NativeWikitextEditorViewController: FindAndReplaceKeyboardBarDisplayDelegate {
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar) {
        print("replace in text storage")
    }
    
    func keyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar) {
        print("??")
    }
    
    func keyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar) {
        print("??")
    }
}

// MARK: Selection Formatting Determination Methods

private extension NativeWikitextEditorViewController {
    
    func targetSelectedRangeAndAttributedText() -> (NSRange, NSAttributedString)? {
        
        let textView = editorView.textView
        
        // Expand selected range before evaluating if necessary
        var selectedRange = textView.selectedRange
        
        if selectedRange.length == 0,
           selectedRange.location > 0,
           textView.attributedText.length > 1,
           textView.attributedText.length > textView.selectedRange.location + 1 {
            
            selectedRange = NSRange(location: textView.selectedRange.location - 1, length: 2)
        }

//        if #available(iOS 16.0, *) {
//
//            if let textRange = textView.textLayoutManager?.textSelections.first?.textRanges.first {
//
//                if let paragraphElement = textView.textLayoutManager?.textLayoutFragment(for: textRange.location)?.textElement as? NSTextParagraph,
//                   let contentManager = textView.textContentStorage {
//
//                    let targetAttributedText = paragraphElement.attributedString
//                    if let paragraphContentRange = paragraphElement.paragraphContentRange {
//                        let paragraphContentNSRange = NSRange(paragraphContentRange, in: contentManager)
//                        let targetSelectedRange = NSRange(location: selectedRange.location - paragraphContentNSRange.location, length: selectedRange.length)
//                        guard targetSelectedRange.location >= 0 else {
//                            return nil
//                        }
//                        return (targetSelectedRange, targetAttributedText)
//                    }
//                }
//            }
//
//            return nil
//
//        } else {
            return (selectedRange, textView.attributedText)
        // }
    }
    
    struct SelectedTextRangeFormattingValues {
        let isBold: Bool
        let isItalic: Bool
        let isLink: Bool
        let isImage: Bool
        let isH2: Bool
        let isH3: Bool
        let isH4: Bool
        let isH5: Bool
        let isH6: Bool
        let isTemplate: Bool
        let isReference: Bool
        let isSuperscript: Bool
        let isSubscript: Bool
        let isUnderline: Bool
        let isStrikethrough: Bool
        let isListBullet: Bool
        let isListNumber: Bool
        let isComment: Bool
    }
    
    func formattingValuesForSelectedTextRangeOrCursor() -> SelectedTextRangeFormattingValues {
        
        var isBold: Bool = false
        var isItalic: Bool = false
        var isLink: Bool = false
        var isImage: Bool = false
        var isH2: Bool = false
        var isH3: Bool = false
        var isH4: Bool = false
        var isH5: Bool = false
        var isH6: Bool = false
        var isTemplate: Bool = false
        var isReference: Bool = false
        var isSuperscript: Bool = false
        var isSubscript: Bool = false
        var isUnderline: Bool = false
        var isStrikethrough: Bool = false
        var isListBullet: Bool = false
        var isListNumber: Bool = false
        var isComment: Bool = false
        
        if let targetSelectionValues = targetSelectedRangeAndAttributedText() {
            
            let range = targetSelectionValues.0
            let attributedString = targetSelectionValues.1
            
            attributedString.enumerateAttributes(in:range, options:.longestEffectiveRangeNotRequired) { attributes, range, stop in
                if attributes[.wikitextBoldAndItalic] != nil {
                    isBold = true
                    isItalic = true
                }
                
                if !isBold && attributes[.wikitextBold] != nil {
                    isBold = true
                }
                
                if !isItalic && attributes[.wikitextItalic] != nil {
                    isItalic = true
                }
                
                if attributes[.wikitextLink] !=  nil {
                    isLink = true
                }
                
                if attributes[.wikitextImage] !=  nil {
                    isImage = true
                }
                
                if attributes[.wikitextH2] != nil {
                    isH2 = true
                }
                
                if attributes[.wikitextH3] != nil {
                    isH3 = true
                }
                
                if attributes[.wikitextH4] != nil {
                    isH4 = true
                }
                
                if attributes[.wikitextH5] != nil {
                    isH5 = true
                }
                
                if attributes[.wikitextH6] != nil {
                    isH6 = true
                }
                
                if attributes[.wikitextTemplate] != nil {
                    isTemplate = true
                }
                
                if attributes[.wikitextRef] != nil {
                    isReference = true
                }
                
                if attributes[.wikitextSuperscript] != nil {
                    isSuperscript = true
                }
                
                if attributes[.wikitextSubscript] != nil {
                    isSubscript = true
                }
                
                if attributes[.wikitextUnderline] != nil {
                    isUnderline = true
                }
                
                if attributes[.wikitextStrikethrough] != nil {
                    isStrikethrough = true
                }
                
                if attributes[.wikitextListBullet] != nil {
                    isListBullet = true
                }
                
                if attributes[.wikitextListNumber] != nil {
                    isListNumber = true
                }
                
                if attributes[.wikitextComment] != nil {
                    isComment = true
                }
            }
        }
        
        return SelectedTextRangeFormattingValues(isBold: isBold, isItalic: isItalic, isLink: isLink, isImage: isImage, isH2: isH2, isH3: isH3, isH4: isH4, isH5: isH5, isH6: isH6, isTemplate: isTemplate, isReference: isReference, isSuperscript: isSuperscript, isSubscript: isSubscript, isUnderline: isUnderline, isStrikethrough: isStrikethrough, isListBullet: isListBullet, isListNumber: isListNumber, isComment: isComment)
    }
}

// MARK: Link and Image Helpers

private extension NativeWikitextEditorViewController {
    
    func extractLinkInfoFromSelectedRange() -> (linkText: String, labelText: String, linkExists: Bool)? {
        
        let textView = editorView.textView
        guard let range =  textView.selectedTextRange else { return nil }
        
        // Need to save this off for later when user returns from insert & edit link view controllers
        self.preselectedTextRange = range
        
        let text = textView.text(in: range)

        guard let text else { return nil }

        var doesLinkExist = false

        if let start = textView.position(from: range.start, offset: -2),
           let end = textView.position(from: range.end, offset: 2),
           let newSelectedRange = textView.textRange(from: start, to: end) {

            if let newText = textView.text(in: newSelectedRange) {
                if newText.contains("[[") || newText.contains("]]") {
                    doesLinkExist = true
                } else {
                    doesLinkExist = false
                }
            }
        }

        let index = text.firstIndex(of: "|") ?? text.endIndex
        let beggining = text[..<index]

        let ending = text[index...]

        let newSearchTerm = String(beggining)
        let newLabel = String(ending.dropFirst())

        let linkText = doesLinkExist ? newSearchTerm : text
        let labelText = doesLinkExist ? newLabel : text

        return (linkText, labelText, doesLinkExist)
    }
    
    func insertLink(page: String) {
        
        let textView = editorView.textView
        guard let textRange = preselectedTextRange else {
            return
        }
        
        var content = "[[\(page)]]"

        if let selectedText = textView.text(in: textRange) {
            if selectedText.isEmpty || page == selectedText {
                content = "[[\(page)]]"
            } else if page != selectedText {
                content = "[[\(page)|\(selectedText)]]"
            }
        }
        textView.replace(textRange, withText: content)

        let newStartPosition = textView.position(from: textRange.start, offset: 2)
        let newEndPosition = textView.position(from: textRange.start, offset: content.count-2)
        textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
    }
    
    func editLink(page: String, label: String?) {
        
        let textView = editorView.textView
        guard let textRange = preselectedTextRange else {
            return
        }
        
        if let label, !label.isEmpty {
            textView.replace(textRange, withText: "\(page)|\(label)")
        } else {
            textView.replace(textRange, withText: "\(page)")
        }
    }
    
    func removeLink() {
        let textView = editorView.textView
        guard let range =  preselectedTextRange else {
            return
        }

        guard let start = textView.position(from: range.start, offset: -2),
              let end = textView.position(from: range.end, offset: 2),
            let newSelectedRange = textView.textRange(from: start, to: end) else {
              return
          }
               
        textView.replace(newSelectedRange, withText: textView.text(in: range) ?? String())

        let newStartPosition = textView.position(from: range.start, offset: -2)
        let newEndPosition = textView.position(from: range.end, offset: -2)
        textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
    }
    
    func insertImage(wikitext: String) {
        let textView = editorView.textView
        guard let textRange = preselectedTextRange else {
            return
        }
        
        textView.replace(textRange, withText: wikitext)

        let newStartPosition = textView.position(from: textRange.start, offset: 2)
        let newEndPosition = textView.position(from: textRange.start, offset: wikitext.count-2)
        textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
    }
}

// MARK: Programmatic Selection Methods

private extension NativeWikitextEditorViewController {
    
    func addOrRemoveFormattingStringFromSelectedText(formattingString: String, shouldAddFormatting: Bool) {
        if !shouldAddFormatting {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: formattingString, endingFormattingString: formattingString)
            if selectedRangeIsSurroundedByFormattingString(formattingString: formattingString) {
                removeSurroundingFormattingStringFromSelectedRange(formattingString: formattingString)
            }
        } else {
            addStringFormattingCharacters(formattingString: formattingString)
        }
    }
    
    func addOrRemoveFormattingStringFromSelectedText(startingFormattingString: String, endingFormattingString: String, shouldAddFormatting: Bool) {
        if !shouldAddFormatting {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString)
            if selectedRangeIsSurroundedByFormattingString(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString) {
                removeSurroundingFormattingStringFromSelectedRange(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString)
            }
        } else {
            addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString)
        }
    }
    
    func expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String) {
        
        let textView = editorView.textView
        
        if let textPositions = textPositionsConsideringNearestFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString) {
            textView.selectedTextRange = textView.textRange(from: textPositions.startRange, to: textPositions.endRange)
        }
    }
    
    func textPositionsConsideringNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String) -> (startRange: UITextPosition, endRange: UITextPosition)? {
        
        let textView = editorView.textView
        
        guard let originalSelectedRange = textView.selectedTextRange else {
            return nil
        }
        
        let breakOnOppositeTag = startingFormattingString != endingFormattingString
        
        // loop backwards to find start
        var i = 0
        var finalStart: UITextPosition?
        while let newStart = textView.position(from: originalSelectedRange.start, offset: i) {
            let newRange = textView.textRange(from: newStart, to: originalSelectedRange.end)

            if rangeIsPrecededByFormattingString(range: newRange, formattingString: startingFormattingString) {

                finalStart = newStart
                break
            }
            
            if rangeIsPrecededByFormattingString(range: newRange, formattingString: "\n") {
                break
            }
            
            if breakOnOppositeTag && rangeIsPrecededByFormattingString(range: newRange, formattingString: endingFormattingString) {
                break
            }
            
            i = i - 1
        }
        
        // loop forwards to find end
        i = 0
        var finalEnd: UITextPosition?
        while let newEnd = textView.position(from: originalSelectedRange.end, offset: i) {
            let newRange = textView.textRange(from: originalSelectedRange.start, to: newEnd)
            
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: endingFormattingString) {

                finalEnd = newEnd
                break
            }
            
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: "\n") {
                break
            }
            
            if breakOnOppositeTag && rangeIsFollowedByFormattingString(range: newRange, formattingString: startingFormattingString) {
                break
            }
            
            i = i + 1
        }
        
        // Select new range
        guard let finalStart = finalStart,
                  let finalEnd = finalEnd else {
                      return nil
                  }
        
        return (finalStart, finalEnd)
    }
    
    func selectedRangeIsSurroundedByFormattingString(startingFormattingString: String, endingFormattingString: String) -> Bool {
        let textView = editorView.textView
        return rangeIsPrecededByFormattingString(range: textView.selectedTextRange, formattingString: startingFormattingString) && rangeIsFollowedByFormattingString(range: textView.selectedTextRange, formattingString: endingFormattingString)
    }
    
    func selectedRangeIsSurroundedByFormattingString(formattingString: String) -> Bool {
        let textView = editorView.textView
        
        return rangeIsPrecededByFormattingString(range: textView.selectedTextRange, formattingString: formattingString) && rangeIsFollowedByFormattingString(range: textView.selectedTextRange, formattingString: formattingString)
    }
    
    func rangeIsPrecededByFormattingString(range: UITextRange?, formattingString: String) -> Bool {
        let textView = editorView.textView
        guard let range = range,
              let newStart = textView.position(from: range.start, offset: -formattingString.count) else {
            return false
        }
        
        guard let startingRange = textView.textRange(from: newStart, to: range.start),
              let startingString = textView.text(in: startingRange) else {
            return false
        }
        
        return startingString == formattingString
    }
    
    func rangeIsFollowedByFormattingString(range: UITextRange?, formattingString: String) -> Bool {
        let textView = editorView.textView
        guard let range = range,
              let newEnd = textView.position(from: range.end, offset: formattingString.count) else {
            return false
        }
        
        guard let endingRange = textView.textRange(from: range.end, to: newEnd),
              let endingString = textView.text(in: endingRange) else {
            return false
        }
        
        return endingString == formattingString
    }
    
    func removeSurroundingFormattingStringFromSelectedRange(formattingString: String) {
        removeSurroundingFormattingStringFromSelectedRange(startingFormattingString: formattingString, endingFormattingString: formattingString)
    }
    
    // Check selectedRangeIsSurroundedByFormattingString first before running this
    func removeSurroundingFormattingStringFromSelectedRange(startingFormattingString: String, endingFormattingString: String) {
        
        let textView = editorView.textView

        guard let originalSelectedTextRange = textView.selectedTextRange,
              let formattingTextStart = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
              let formattingTextEnd = textView.position(from: originalSelectedTextRange.end, offset: endingFormattingString.count) else {
            return
        }
        
        guard let formattingTextStartRange = textView.textRange(from: formattingTextStart, to: originalSelectedTextRange.start),
              let formattingTextEndRange = textView.textRange(from: originalSelectedTextRange.end, to: formattingTextEnd) else {
            return
        }
        
        // Note: replacing end first ordering is important here, otherwise range gets thrown off if you begin with start. Check with RTL
        textView.replace(formattingTextEndRange, withText: "")
        textView.replace(formattingTextStartRange, withText: "")

        // Reset selection
        let delta = endingFormattingString.count - startingFormattingString.count
        guard
            let newSelectionStartPosition = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
            let newSelectionEndPosition = textView.position(from: originalSelectedTextRange.end, offset: -endingFormattingString.count + delta) else {
            return
        }

        textView.selectedTextRange = textView.textRange(from: newSelectionStartPosition, to: newSelectionEndPosition)
    }
    
    /// Adds formatting characters around selected text or around cursor
    /// - Parameters:
    ///   - formattingString: string used for formatting, will surround selected text or cursor
    func addStringFormattingCharacters(startingFormattingString: String, endingFormattingString: String) {
        
        let textView = editorView.textView
        let startingCursorOffset = startingFormattingString.count
        let endingCursorOffset = endingFormattingString.count
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.endOfDocument, to: selectedRange.end)
            if selectedRange.isEmpty {
                textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + endingFormattingString)

                let newPosition = textView.position(from: textView.endOfDocument, offset: cursorPosition - endingCursorOffset)
                textView.selectedTextRange = textView.textRange(from: newPosition ?? textView.endOfDocument, to: newPosition ?? textView.endOfDocument)
            } else {
                if let selectedSubstring = textView.text(in: selectedRange) {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + selectedSubstring + endingFormattingString)

                    let delta = endingFormattingString.count - startingFormattingString.count
                    let newStartPosition = textView.position(from: selectedRange.start, offset: startingCursorOffset)
                    let newEndPosition = textView.position(from: selectedRange.end, offset: endingCursorOffset - delta)
                    textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
                } else {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + endingFormattingString)
                }
            }
        }
    }
    
    func addStringFormattingCharacters(formattingString: String) {
        addStringFormattingCharacters(startingFormattingString: formattingString, endingFormattingString: formattingString)
    }
}

extension NativeWikitextEditorViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        preselectedTextRange = nil
        dismiss(animated: true)
    }
    
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        insertLink(page: page)
        preselectedTextRange = nil
        dismiss(animated: true)
    }
}

extension NativeWikitextEditorViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        preselectedTextRange = nil
        dismiss(animated: true)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        editLink(page: linkTarget, label: displayText)
        preselectedTextRange = nil
        dismiss(animated: true)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        preselectedTextRange = nil
        dismiss(animated: true)
    }
    
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        removeLink()
        preselectedTextRange = nil
        dismiss(animated: true)
    }
}

extension NativeWikitextEditorViewController: InsertMediaViewControllerDelegate {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String) {
        insertImage(wikitext: wikitext)
        preselectedTextRange = nil
        dismiss(animated: true)
    }
}

extension UITextView {

    @available(iOS 16.0, *)
    var textContentStorage: NSTextContentStorage? {
        return textLayoutManager?.textContentManager as? NSTextContentStorage
    }

}

extension NSRange {
    @available(iOS 15.0, *)
    init(_ textRange: NSTextRange, in textContentManager: NSTextContentManager) {
        let location = textContentManager.offset(from: textContentManager.documentRange.location, to: textRange.location)
        let length = textContentManager.offset(from: textRange.location, to: textRange.endLocation)
        self.init(location: location, length: length)
    }
}
