import Foundation
import UIKit

protocol WKSourceEditorViewDelegate: AnyObject {
    func editorViewTextSelectionDidChange(editorView: WKSourceEditorView, isRangeSelected: Bool)
    func editorViewDidTapFind(editorView: WKSourceEditorView)
    func editorViewDidTapFormatText(editorView: WKSourceEditorView)
    func editorViewDidTapFormatHeading(editorView: WKSourceEditorView)
    func editorViewDidTapCloseInputView(editorView: WKSourceEditorView, isRangeSelected: Bool)
    func editorViewDidTapShowMore(editorView: WKSourceEditorView)
}

class WKSourceEditorView: WKComponentView {
    
    // MARK: Nested Types
    
    enum InputViewType {
        case main
        case headerSelect
    }
    
    enum InputAccessoryViewType {
        case expanding
        case highlight
        case find
    }
    
    // MARK: - Properties

    private lazy var textView: UITextView = {
        let textStorage = NSTextStorage()

        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()
        
        container.widthTracksTextView = true
        
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        let textView = UITextView(frame: bounds, textContainer: container)
        
        textView.textContainerInset = .init(top: 16, left: 8, bottom: 16, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardDismissMode = .interactive
        textView.delegate = self
        
        return textView
    }()
    
    private lazy var expandingAccessoryView: WKEditorToolbarExpandingView = {
        let view = UINib(nibName: String(describing: WKEditorToolbarExpandingView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKEditorToolbarExpandingView
        view.delegate = self
        return view
    }()
    
    private lazy var highlightAccessoryView: WKEditorToolbarHighlightView = {
        let view = UINib(nibName: String(describing: WKEditorToolbarHighlightView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKEditorToolbarHighlightView
        view.delegate = self
        
        return view
    }()
    
    private lazy var findAccessoryView: WKFindAndReplaceView = {
        let view = UINib(nibName: String(describing: WKFindAndReplaceView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKFindAndReplaceView
        let viewModel = WKFindAndReplaceViewModel()
        view.configure(viewModel: viewModel)
        
        return view
    }()
    
    private var _mainInputView: UIView?
    private var mainInputView: UIView? {
        get {
            guard _mainInputView == nil else {
                return _mainInputView
            }
            
            let inputViewController = WKEditorInputViewController(configuration: .rootMain, delegate: self)
            inputViewController.loadViewIfNeeded()
            
            _mainInputView = inputViewController.view
           
            return inputViewController.view
        }
        set {
            _mainInputView = newValue
        }
    }
    
    private var _headerSelectionInputView: UIView?
    private var headerSelectionInputView: UIView? {
        get {
            guard _headerSelectionInputView == nil else {
                return _headerSelectionInputView
            }
            
            let inputViewController = WKEditorInputViewController(configuration: .rootHeaderSelect, delegate: self)
            inputViewController.loadViewIfNeeded()
            
            _headerSelectionInputView = inputViewController.view
            
           return inputViewController.view
        }
        set {
            _headerSelectionInputView = newValue
        }
    }
    
    private weak var delegate: WKSourceEditorViewDelegate?
    
    // MARK: - Lifecycle

    required init(delegate: WKSourceEditorViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(textView)
        updateColors()
        
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: textView.topAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
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
    
    // MARK: Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Notifications
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        updateInsets(keyboardHeight: 0)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let height = max(frame.height - safeAreaInsets.bottom, 0)
            updateInsets(keyboardHeight: height)
        }
    }
    
    // MARK: - Internal
    
    var inputViewType: InputViewType? = nil {
        didSet {
            
            guard let inputViewType else {
                mainInputView = nil
                headerSelectionInputView = nil
                textView.inputView = nil
                textView.reloadInputViews()
                return
            }
            
            switch inputViewType {
            case .main:
                textView.inputView = mainInputView
            case .headerSelect:
                textView.inputView = headerSelectionInputView
            }
            
            textView.inputAccessoryView = nil
            textView.reloadInputViews()
        }
    }
    var inputAccessoryViewType: InputAccessoryViewType? = nil {
        didSet {
            
            guard let inputAccessoryViewType else {
                textView.inputAccessoryView = nil
                textView.reloadInputViews()
                return
            }
            
            switch inputAccessoryViewType {
            case .expanding:
                textView.inputAccessoryView = expandingAccessoryView
            case .highlight:
                textView.inputAccessoryView = highlightAccessoryView
            case .find:
                textView.inputAccessoryView = findAccessoryView
            }
            
            textView.inputView = nil
            textView.reloadInputViews()
        }
    }
    
    func setInitialText(_ text: String) {
        textView.attributedText = NSAttributedString(string: text)
    }
    
    func closeFind() {
        textView.becomeFirstResponder()
    }
    
    // MARK: - Private Helpers
    
    private func updateInsets(keyboardHeight: CGFloat) {
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }
    
    private func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.paperBackground
        textView.backgroundColor = WKAppEnvironment.current.theme.paperBackground
        textView.textColor = WKAppEnvironment.current.theme.text
        textView.keyboardAppearance = WKAppEnvironment.current.theme.keyboardAppearance
    }
}


// MARK: - UITextViewDelegate

extension WKSourceEditorView: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.editorViewTextSelectionDidChange(editorView: self, isRangeSelected: textView.selectedRange.length > 0)
    }
}

// MARK: - WKEditorToolbarExpandingViewDelegate

extension WKSourceEditorView: WKEditorToolbarExpandingViewDelegate {
    func toolbarExpandingViewDidTapFind(toolbarView: WKEditorToolbarExpandingView) {
        delegate?.editorViewDidTapFind(editorView: self)
    }
    
    func toolbarExpandingViewDidTapFormatText(toolbarView: WKEditorToolbarExpandingView) {
        delegate?.editorViewDidTapFormatText(editorView: self)
    }
    
    func toolbarExpandingViewDidTapFormatHeading(toolbarView: WKEditorToolbarExpandingView) {
        delegate?.editorViewDidTapFormatHeading(editorView: self)
    }
}

// MARK: - WKEditorToolbarHighlightViewDelegate

extension WKSourceEditorView: WKEditorToolbarHighlightViewDelegate {
    func toolbarHighlightViewDidTapShowMore(toolbarView: WKEditorToolbarHighlightView) {
        delegate?.editorViewDidTapShowMore(editorView: self)
    }
    
    func toolbarHighlightViewDidTapFormatHeading(toolbarView: WKEditorToolbarHighlightView) {
        delegate?.editorViewDidTapFormatHeading(editorView: self)
    }
}

// MARK: - WKEditorInputViewDelegate

extension WKSourceEditorView: WKEditorInputViewDelegate {
    func didTapClose() {
        delegate?.editorViewDidTapCloseInputView(editorView: self, isRangeSelected: textView.selectedRange.length > 0)
    }
}
