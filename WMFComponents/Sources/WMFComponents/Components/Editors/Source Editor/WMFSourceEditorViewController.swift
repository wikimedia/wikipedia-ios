import Foundation
import UIKit

public protocol WMFSourceEditorViewControllerDelegate: AnyObject {
    func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: WMFSourceEditorViewController)
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: WMFSourceEditorViewController)
    func sourceEditorViewControllerDidTapLink(parameters: WMFSourceEditorFormatterLinkWizardParameters)
    func sourceEditorViewControllerDidTapImage()
    func sourceEditorDidChangeUndoState(_ sourceEditorViewController: WMFSourceEditorViewController, canUndo: Bool, canRedo: Bool)
    func sourceEditorDidChangeText(_ sourceEditorViewController: WMFSourceEditorViewController, didChangeText: Bool)
}

// MARK: NSNotification Names

extension Notification.Name {
    static let WMFSourceEditorSelectionState = Notification.Name("WMFSourceEditorSelectionState")
}

extension Notification {
    static let WMFSourceEditorSelectionState = Notification.Name.WMFSourceEditorSelectionState
    static let WMFSourceEditorSelectionStateKey = "WMFSourceEditorSelectionStateKey"
}

public class WMFSourceEditorViewController: WMFComponentViewController {
    
    // MARK: Nested Types

    enum InputAccessoryViewType {
        case expanding
        case highlight
        case find
    }
    
    enum CursorDirection {
        case up
        case down
        case left
        case right
    }
    
    // MARK: - Properties
    
    private let viewModel: WMFSourceEditorViewModel
    private weak var delegate: WMFSourceEditorViewControllerDelegate?
    private let textFrameworkMediator: WMFSourceEditorTextFrameworkMediator
    private var scrollingToMatchCount: Int? = nil
    private var preselectedTextRange: UITextRange?
    
    var textView: UITextView {
        return textFrameworkMediator.textView
    }
    
    public var editedWikitext: String {
        return textView.text
    }
    
    // Input Accessory Views
    
    private(set) lazy var expandingAccessoryView: WMFEditorToolbarExpandingView = {
        let view = UINib(nibName: String(describing: WMFEditorToolbarExpandingView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WMFEditorToolbarExpandingView
        view.delegate = self
        view.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.expandingToolbar
        return view
    }()
    
    private lazy var highlightAccessoryView: WMFEditorToolbarHighlightView = {
        let view = UINib(nibName: String(describing: WMFEditorToolbarHighlightView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WMFEditorToolbarHighlightView
        view.delegate = self
        view.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.highlightToolbar
        return view
    }()
    
    private lazy var findAccessoryView: WMFFindAndReplaceView = {
        let view = UINib(nibName: String(describing: WMFFindAndReplaceView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WMFFindAndReplaceView
        view.update(viewModel: WMFFindAndReplaceViewModel())
        view.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.findToolbar
        view.delegate = self
        return view
    }()
    
    // Input Views
    
    private lazy var editorInputView: UIView? = {
        let inputView = WMFEditorInputView(delegate: self)
        inputView.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.inputView
        return inputView
    }()
    
    // Input Tracking Properties
    
    var editorInputViewIsShowing: Bool? = false {
        didSet {
            
            guard editorInputViewIsShowing == true else {
                textView.inputView = nil
                textView.reloadInputViews()
                return
            }
            
            textView.inputView = editorInputView
            textView.inputAccessoryView = nil
            textView.reloadInputViews()
        }
    }
    var inputAccessoryViewType: InputAccessoryViewType? = nil {
        didSet {
            
            guard let inputAccessoryViewType,
                  !viewModel.needsReadOnly else {
                textView.inputAccessoryView = nil
                textView.reloadInputViews()
                return
            }
            
            if oldValue == .find && inputAccessoryViewType != .find {
                delegate?.sourceEditorViewControllerDidRemoveFindInputAccessoryView(self)
            }
            
            switch inputAccessoryViewType {
            case .expanding:
                textView.inputAccessoryView = expandingAccessoryView
            case .highlight:
                textView.inputAccessoryView = highlightAccessoryView
            case .find:
                textView.inputAccessoryView = findAccessoryView
                findAccessoryView.focus()
            }
            
            textView.inputView = nil
            textView.reloadInputViews()
        }
    }
    
    // MARK: - Lifecycle
    
    public init(viewModel: WMFSourceEditorViewModel, delegate: WMFSourceEditorViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.textFrameworkMediator = WMFSourceEditorTextFrameworkMediator(viewModel: viewModel)
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        textView.delegate = self
        textFrameworkMediator.delegate = self
        textView.isEditable = !viewModel.needsReadOnly
        textView.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.wikitextEditorAccessibility
        
        view.addSubview(textView)
        updateColorsAndFonts()
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: textView.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIApplication.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIApplication.keyboardWillHideNotification,
                                               object: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        load(viewModel: viewModel)
        inputAccessoryViewType = .expanding
    }
    
    // MARK: Overrides
    
    public override func appEnvironmentDidChange() {
        updateColorsAndFonts()
    }
    
    public override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(toggleBoldFormattingFromKeyboard)),
            UIKeyCommand(input: "i", modifierFlags: .command, action: #selector(toggleItalicsFormattingFromKeyboard))
        ]
    }
    
    // MARK: - Notifications
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        updateInsets(keyboardHeight: 0)
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let height = max(frame.height - view.safeAreaInsets.bottom, 0)
            updateInsets(keyboardHeight: height)
        }
    }
    
    // MARK: - Public
    
    public func closeFind() {
        textView.isEditable = true
        textView.isSelectable = true
        textView.becomeFirstResponder()
        
        if let currentRange = textFrameworkMediator.findAndReplaceFormatter?.selectedMatchRange,
           currentRange.location != NSNotFound {
            textView.selectedRange = currentRange
        } else if let lastReplacedRange = textFrameworkMediator.findAndReplaceFormatter?.lastReplacedRange,
                  lastReplacedRange.location != NSNotFound {
            textView.selectedRange = lastReplacedRange
        } else {
            if let visibleRange = textView.visibleRange {
                textView.selectedRange = NSRange(location: visibleRange.location, length: 0)
            } else {
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        }
        
        inputAccessoryViewType = .expanding
        resetFind(fromClose: true)
    }
    
    public func toggleSyntaxHighlighting() {
        viewModel.isSyntaxHighlightingEnabled.toggle()
        update(viewModel: viewModel)
    }
    
    public func insertLink(pageTitle: String) {
        
        guard let preselectedTextRange else {
            return
        }
        
        textFrameworkMediator.linkFormatter?.insertLink(in: textView, pageTitle: pageTitle, preselectedTextRange: preselectedTextRange)
        
        self.preselectedTextRange = nil
    }
    
    public func editLink(newPageTitle: String, newPageLabel: String?) {
        
        guard let preselectedTextRange else {
            return
        }
        
        textFrameworkMediator.linkFormatter?.editLink(in: textView, newPageTitle: newPageTitle, newPageLabel: newPageLabel, preselectedTextRange: preselectedTextRange)
        
        self.preselectedTextRange = nil
    }
    
    public func removeLink() {
        
        guard let preselectedTextRange else {
            return
        }
        
        textFrameworkMediator.linkFormatter?.removeLink(in: textView, preselectedTextRange: preselectedTextRange)
        
        self.preselectedTextRange = nil
    }
    
    public func insertImage(wikitext: String) {
        textFrameworkMediator.linkFormatter?.insertImage(wikitext: wikitext, in: textView)
    }
    
    public func undo() {
        textView.undoManager?.undo()
    }
    
    public func redo() {
        textView.undoManager?.redo()
    }
    
    public func removeFocus() {
        textView.resignFirstResponder()
    }
}

// MARK: - Private

private extension WMFSourceEditorViewController {

    func load(viewModel: WMFSourceEditorViewModel) {
        textFrameworkMediator.isSyntaxHighlightingEnabled = viewModel.isSyntaxHighlightingEnabled
        textView.attributedText = NSAttributedString(string: viewModel.initialText)
        scrollToOnloadSelectRangeIfNeeded()
    }
    
    private func scrollToOnloadSelectRangeIfNeeded() {
        if let onloadSelectRange = viewModel.onloadSelectRange,
           !viewModel.needsReadOnly {
            
            guard onloadSelectRange.location != NSNotFound else {
                assertionFailure("onloadSelectRange is invalid (NSNotFound)")
                return
            }
                
            textView.scrollRangeToVisible(onloadSelectRange)
            textView.becomeFirstResponder()
            textView.selectedRange = onloadSelectRange
        }
    }
    
    func update(viewModel: WMFSourceEditorViewModel) {
        textFrameworkMediator.isSyntaxHighlightingEnabled = viewModel.isSyntaxHighlightingEnabled
    }
    
    func updateInsets(keyboardHeight: CGFloat) {
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }
    
    func updateColorsAndFonts() {
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
        textView.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
        textView.keyboardAppearance = WMFAppEnvironment.current.theme.keyboardAppearance
        textFrameworkMediator.updateColorsAndFonts()
    }
    
    func selectionState() -> WMFSourceEditorSelectionState {
        return textFrameworkMediator.selectionState(selectedDocumentRange: textView.selectedRange)
    }
    
    func postUpdateButtonSelectionStatesNotification(withDelay delay: Bool) {
        let selectionState = selectionState()
        if delay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: Notification.WMFSourceEditorSelectionState, object: nil, userInfo: [Notification.WMFSourceEditorSelectionStateKey: selectionState])
            }
        } else {
            NotificationCenter.default.post(name: Notification.WMFSourceEditorSelectionState, object: nil, userInfo: [Notification.WMFSourceEditorSelectionStateKey: selectionState])
        }
    }
    
    func presentLinkWizard(linkButtonIsSelected: Bool) {
        
        let action: WMFSourceEditorFormatterLinkButtonAction = linkButtonIsSelected ? .edit : .insert

        guard let parameters = textFrameworkMediator.linkFormatter?.linkWizardParameters(action: action, in: textView) else {
            return
        }
        
        // For some reason the editor text view can lose its selectedTextRange when presenting the link wizard, which we need in the formatter button action extension to determine how to change the text after wizard dismissal. We keep track of it here and send it back into the formatter later.
        self.preselectedTextRange = parameters.preselectedTextRange
        delegate?.sourceEditorViewControllerDidTapLink(parameters: parameters)
    }
    
    func resetFind(fromClose: Bool) {
        guard var viewModel = findAccessoryView.viewModel else {
            return
        }
        viewModel.reset()
        findAccessoryView.update(viewModel: viewModel)
        if fromClose {
            findAccessoryView.clearFind()
            findAccessoryView.resetReplace()
        }
        textFrameworkMediator.findReset()
    }
    
    func updateFindViewModelState() {
        
        guard var viewModel = findAccessoryView.viewModel,
              let findFormatter = textFrameworkMediator.findAndReplaceFormatter else {
            return
        }
        
        if findFormatter.selectedMatchIndex != NSNotFound {
            let selectedMatch = findFormatter.selectedMatchIndex + 1
            let totalMatchCount = findFormatter.matchCount
            viewModel.currentMatchInfo = "\(selectedMatch) / \(totalMatchCount)"
            viewModel.currentMatchInfoAccessibility = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.findCurrentMatchInfoFormatAccessibility, "\(totalMatchCount)", "\(selectedMatch)")
        } else if findFormatter.matchCount == 0 {
            viewModel.currentMatchInfo = "0 / 0"
            viewModel.currentMatchInfoAccessibility = WMFSourceEditorLocalizedStrings.current.findCurrentMatchInfoZeroResultsAccessibility
        } else {
            viewModel.currentMatchInfo = nil
            viewModel.currentMatchInfoAccessibility = nil
        }
        
        viewModel.nextPrevButtonsAreEnabled = findFormatter.matchCount > 0
        viewModel.matchCount = findFormatter.matchCount
        findAccessoryView.update(viewModel: viewModel)
    }
    
    func moveCursor(direction: CursorDirection) {
        
        guard let cursorPos = textView.selectedTextRange?.start else {
            return
        }
        
        switch direction {
        case .up, .down:
            
            let cursorPosRect = textView.caretRect(for: cursorPos)
            let yMiddle = cursorPosRect.origin.y + (cursorPosRect.height / 2)
            let lineHeight = textFrameworkMediator.fonts.baseFont.lineHeight
            
            let point: CGPoint
            if case .up = direction {
                point = CGPoint(x: cursorPosRect.origin.x, y: yMiddle - lineHeight)
            } else {
                point = CGPoint(x: cursorPosRect.origin.x, y: yMiddle + lineHeight)
            }
            
            if let textRangeAtPoint = textView.characterRange(at: point) {
                let textRangeCursor = textView.textRange(from: textRangeAtPoint.end, to: textRangeAtPoint.end)
                textView.selectedTextRange = textRangeCursor
            }
        case .left, .right:
            
            let pos: UITextPosition?
            
            if case .left = direction {
                pos = textView.position(from: cursorPos, offset: -1)
            } else {
                pos = textView.position(from: cursorPos, offset: +1)
            }
            
            if let pos,
               let textRangeCursor = textView.textRange(from: pos, to: pos) {
                textView.selectedTextRange = textRangeCursor
            }
        }
    }
    
    @objc func toggleBoldFormattingFromKeyboard() {
        let selectionState = selectionState()
        let action: WMFSourceEditorFormatterButtonAction = selectionState.isBold ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleBoldFormatting(action: action, in: textView)
    }
    
    @objc func toggleItalicsFormattingFromKeyboard() {
        let selectionState = selectionState()
        let action: WMFSourceEditorFormatterButtonAction = selectionState.isItalics ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleItalicsFormatting(action: action, in: textView)
    }
}

// MARK: - UITextViewDelegate

extension WMFSourceEditorViewController: UITextViewDelegate {
    public func textViewDidChangeSelection(_ textView: UITextView) {
        
        guard !viewModel.needsReadOnly else {
            // Selecting text in read only mode should not change any input or input accessory views.
            return
        }
        
        guard editorInputViewIsShowing == false else {
            postUpdateButtonSelectionStatesNotification(withDelay: false)
            return
        }
        
        if inputAccessoryViewType == .find {
            return
        }
        
        let isRangeSelected = textView.selectedRange.length > 0
        inputAccessoryViewType = isRangeSelected ? .highlight : .expanding
        postUpdateButtonSelectionStatesNotification(withDelay: false)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        
        DispatchQueue.main.async {
            self.delegate?.sourceEditorDidChangeUndoState(self, canUndo: textView.undoManager?.canUndo ?? false, canRedo: textView.undoManager?.canRedo ?? false)
        }
        
        delegate?.sourceEditorDidChangeText(self, didChangeText: textView.attributedText.string != viewModel.initialText)
    }
}

// MARK: - WMFEditorToolbarExpandingViewDelegate

extension WMFSourceEditorViewController: WMFEditorToolbarExpandingViewDelegate {
    
    func toolbarExpandingViewDidTapFind(toolbarView: WMFEditorToolbarExpandingView) {
        inputAccessoryViewType = .find
        delegate?.sourceEditorViewControllerDidTapFind(self)
        
        if let visibleRange = textView.visibleRange {
            textView.selectedRange = NSRange(location: visibleRange.location, length: 0)
        }
        
        textView.isEditable = false
        textView.isSelectable = false
    }
    
    func toolbarExpandingViewDidTapFormatText(toolbarView: WMFEditorToolbarExpandingView) {
        editorInputViewIsShowing = true
        postUpdateButtonSelectionStatesNotification(withDelay: true)
    }
    
    func toolbarExpandingViewDidTapTemplate(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.templateFormatter?.toggleTemplateFormatting(action: action, in: textView)
    }

    func toolbarExpandingViewDidTapReference(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.referenceFormatter?.toggleReferenceFormatting(action: action, in: textView)
    }

    func toolbarExpandingViewDidTapLink(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool) {
        presentLinkWizard(linkButtonIsSelected: isSelected)
    }
    
    func toolbarExpandingViewDidTapImage(toolbarView: WMFEditorToolbarExpandingView) {
        delegate?.sourceEditorViewControllerDidTapImage()
    }
    
    func toolbarExpandingViewDidTapUnorderedList(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.listFormatter?.toggleListBullet(action: action, in: textView)
    }
    
    func toolbarExpandingViewDidTapOrderedList(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.listFormatter?.toggleListNumber(action: action, in: textView)
    }
    
    func toolbarExpandingViewDidTapIncreaseIndent(toolbarView: WMFEditorToolbarExpandingView) {
        textFrameworkMediator.listFormatter?.tappedIncreaseIndent(currentSelectionState: selectionState(), textView: textView)
    }
    
    func toolbarExpandingViewDidTapDecreaseIndent(toolbarView: WMFEditorToolbarExpandingView) {
        textFrameworkMediator.listFormatter?.tappedDecreaseIndent(currentSelectionState: selectionState(), textView: textView)
    }
    
    func toolbarExpandingViewDidTapCursorUp(toolbarView: WMFEditorToolbarExpandingView) {
        moveCursor(direction: .up)
    }
    
    func toolbarExpandingViewDidTapCursorDown(toolbarView: WMFEditorToolbarExpandingView) {
        moveCursor(direction: .down)
    }
    
    func toolbarExpandingViewDidTapCursorLeft(toolbarView: WMFEditorToolbarExpandingView) {
        moveCursor(direction: .left)
    }
    
    func toolbarExpandingViewDidTapCursorRight(toolbarView: WMFEditorToolbarExpandingView) {
        moveCursor(direction: .right)
    }
}

// MARK: - WMFEditorToolbarHighlightViewDelegate

extension WMFSourceEditorViewController: WMFEditorToolbarHighlightViewDelegate {
        
    func toolbarHighlightViewDidTapBold(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleBoldFormatting(action: action, in: textView)
    }
    
    func toolbarHighlightViewDidTapItalics(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleItalicsFormatting(action: action, in: textView)
    }
    
    func toolbarHighlightViewDidTapTemplate(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.templateFormatter?.toggleTemplateFormatting(action: action, in: textView)
    }

    func toolbarHighlightViewDidTapReference(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.referenceFormatter?.toggleReferenceFormatting(action: action, in: textView)
    }

    func toolbarHighlightViewDidTapLink(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool) {
        presentLinkWizard(linkButtonIsSelected: isSelected)

    }
    
    func toolbarHighlightViewDidTapShowMore(toolbarView: WMFEditorToolbarHighlightView) {
        editorInputViewIsShowing = true
        postUpdateButtonSelectionStatesNotification(withDelay: true)
    }
}

// MARK: - WMFEditorInputViewDelegate

extension WMFSourceEditorViewController: WMFEditorInputViewDelegate {
    func didTapHeading(type: WMFEditorInputView.HeadingButtonType) {
        textFrameworkMediator.headingFormatter?.toggleHeadingFormatting(selectedHeading: type, currentSelectionState: selectionState(), textView: textView)
    }
    
    func didTapBold(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleBoldFormatting(action: action, in: textView)
    }
    
    func didTapItalics(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.boldItalicsFormatter?.toggleItalicsFormatting(action: action, in: textView)
    }
    
    func didTapTemplate(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.templateFormatter?.toggleTemplateFormatting(action: action, in: textView)
    }

    func didTapReference(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.referenceFormatter?.toggleReferenceFormatting(action: action, in: textView)
    }
    
    func didTapBulletList(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.listFormatter?.toggleListBullet(action: action, in: textView)
    }
    
    func didTapNumberList(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.listFormatter?.toggleListNumber(action: action, in: textView)
    }
    
    func didTapIncreaseIndent() {
        textFrameworkMediator.listFormatter?.tappedIncreaseIndent(currentSelectionState: selectionState(), textView: textView)
    }
    
    func didTapDecreaseIndent() {
        textFrameworkMediator.listFormatter?.tappedDecreaseIndent(currentSelectionState: selectionState(), textView: textView)
    }
    
    func didTapStrikethrough(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.strikethroughFormatter?.toggleStrikethroughFormatting(action: action, in: textView)
    }

    func didTapUnderline(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.underlineFormatter?.toggleUnderlineFormatting(action: action, in: textView)
    }

    func didTapSubscript(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.subscriptFormatter?.toggleSubscriptFormatting(action: action, in: textView)
    }

    func didTapSuperscript(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.superscriptFormatter?.toggleSuperscriptFormatting(action: action, in: textView)
    }
    
    func didTapLink(isSelected: Bool) {
        presentLinkWizard(linkButtonIsSelected: isSelected)
    }
    
    func didTapComment(isSelected: Bool) {
        let action: WMFSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        textFrameworkMediator.commentFormatter?.toggleCommentFormatting(action: action, in: textView)
    }

    func didTapClose() {
        editorInputViewIsShowing = false
        let isRangeSelected = textView.selectedRange.length > 0
        inputAccessoryViewType = isRangeSelected ? .highlight : .expanding
    }
}

// MARK: - WMFFindAndReplaceViewDelegate

extension WMFSourceEditorViewController: WMFFindAndReplaceViewDelegate {
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didChangeFindText text: String) {
        resetFind(fromClose: false)
        textFrameworkMediator.findStart(text: text)
        updateFindViewModelState()
    }
    
    func findAndReplaceViewDidTapNext(_ view: WMFFindAndReplaceView) {
        
        textFrameworkMediator.findNext(afterRange: nil)
        updateFindViewModelState()
    }
    
    func findAndReplaceViewDidTapPrevious(_ view: WMFFindAndReplaceView) {
        textFrameworkMediator.findPrevious()
        updateFindViewModelState()
    }
    
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didTapReplaceSingle replaceText: String) {
        textFrameworkMediator.replaceSingle(replaceText: replaceText)
        updateFindViewModelState()
    }
    
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didTapReplaceAll replaceText: String) {
        textFrameworkMediator.replaceAll(replaceText: replaceText)
        updateFindViewModelState()
    }
}

// MARK: - WMFSourceEditorFindAndReplaceScrollDelegate

extension WMFSourceEditorViewController: WMFSourceEditorFindAndReplaceScrollDelegate {
    
    func scrollToCurrentMatch() {
        guard let matchRange = textFrameworkMediator.findAndReplaceFormatter?.selectedMatchRange else {
            return
        }
        guard matchRange.location != NSNotFound else {
            return
        }
        
        if let scrollingToMatchCount {
            self.scrollingToMatchCount = scrollingToMatchCount + 1
        } else {
            self.scrollingToMatchCount = 1
        }
        
        if let startPos = textView.position(from: textView.beginningOfDocument, offset: matchRange.location),
           let endPos = textView.position(from: startPos, offset: matchRange.length),
           let textRange = textView.textRange(from: startPos, to: endPos) {
            let matchRect = textView.firstRect(for: textRange)
            
            textView.scrollRectToVisible(matchRect, animated: false)
            
            // Sometimes scrolling is off, try again.
            if let scrollingToMatchCount,
               scrollingToMatchCount < 2 {
                scrollToCurrentMatch()
            } else {
                scrollingToMatchCount = nil
                textView.flashScrollIndicators()
            }
        }
    }
}
fileprivate extension UITextView {

    var visibleRange: NSRange? {
        if let start = closestPosition(to: contentOffset) {
            if let end = characterRange(at: CGPoint(x: contentOffset.x + bounds.maxX, y: contentOffset.y + bounds.maxY))?.end {
                return NSRange(location: offset(from: beginningOfDocument, to: start), length: offset(from: start, to: end))
            }
        }
        return nil
    }
}
