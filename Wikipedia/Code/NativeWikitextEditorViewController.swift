import UIKit

protocol NativeWikitextEditorDelegate: AnyObject {
    func wikitextViewDidChange(_ textView: UITextView)
}

class NativeWikitextEditorViewController: UIViewController {
    
    weak var delegate: NativeWikitextEditorDelegate?
    
    private lazy var pageEditorInputViewsController: EditorInputViewsController = {
        let inputViewsController = EditorInputViewsController(webView: nil, webMessagingController: nil, findAndReplaceDisplayDelegate: self)
        inputViewsController.delegate = self
        
        return inputViewsController
    }()
    
    private var editorView: NativeWikitextEditorView {
        return view as! NativeWikitextEditorView
    }
    
    init(delegate: NativeWikitextEditorDelegate) {
        self.delegate = delegate
        
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
        let editorView = NativeWikitextEditorView()
        if #available(iOS 16.0, *) {
            editorView.textView.textContentStorage?.delegate = self
        }
        editorView.textView.delegate = self
        view = editorView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override var inputViewController: UIInputViewController? {
        return pageEditorInputViewsController.inputViewController
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
}

extension NativeWikitextEditorViewController: NSTextContentStorageDelegate {
    @available(iOS 15.0, *)
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        guard let originalText = textContentStorage.textStorage?.attributedSubstring(from: range),
              originalText.length > 0 else {
            return nil
        }
        let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
        textWithDisplayAttributes.addWikitextSyntaxFormatting(withSearch: NSRange(location: 0, length: originalText.length), fontSizeTraitCollection: traitCollection, needsColors: true)
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
        pageEditorInputViewsController.textSelectionDidChange(isRangeSelected: textView.selectedRange.length > 0)
//        formattingToolbarView.boldButton.isSelected = selectedTextRangeOrCursorIsBoldAndItalic() || selectedTextRangeOrCursorIsBold()
//        formattingToolbarView.italicsButton.isSelected = selectedTextRangeOrCursorIsBoldAndItalic() || selectedTextRangeOrCursorIsItalic()
//        formattingToolbarView.linkButton.isSelected = selectedTextRangeOrCursorIsLink()
//        formattingToolbarView.templateButton.isSelected = selectedTextRangeOrCursorIsTemplate()
//        formattingToolbarView.refButton.isSelected = selectedTextRangeOrCursorIsRef()
//        formattingToolbarView.h2Button.isSelected = selectedTextRangeOrCursorIsH2()
//        formattingToolbarView.h6Button.isSelected = selectedTextRangeOrCursorIsH6()
//        formattingToolbarView.bulletButton.isSelected = selectedTextRangeOrCursorIsBullet()
//        formattingToolbarView.indentButton.isEnabled = selectedTextRangeOrCursorIsBullet()
//        formattingToolbarView.unindentButton.isEnabled = selectedTextRangeOrCursorIsBullet()
    }
}


extension NativeWikitextEditorViewController: EditorInputViewsControllerDelegate {
    func editorInputViewsControllerDidChangeInputAccessoryView(_ pageEditorInputViewsController: EditorInputViewsController, inputAccessoryView: UIView?) {
        editorView.textView.inputAccessoryView = inputAccessoryView
        editorView.textView.reloadInputViews()
    }
    
    func editorInputViewsControllerDidTapMediaInsert(_ pageEditorInputViewsController: EditorInputViewsController) {
        print("tell delegate to present media insert)")
    }
    
    func editorInputViewsControllerDidTapLinkInsert(_ pageEditorInputViewsController: EditorInputViewsController) {
        print("tell delegate to present link insert)")
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

extension UITextView {

    @available(iOS 16.0, *)
    var textContentStorage: NSTextContentStorage? {
        return textLayoutManager?.textContentManager as? NSTextContentStorage
    }

}
