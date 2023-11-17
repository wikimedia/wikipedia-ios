import Foundation
import UIKit

public protocol WKSourceEditorViewControllerDelegate: AnyObject {
    func sourceEditorViewControllerDidTapFind(sourceEditorViewController: WKSourceEditorViewController)
}

public class WKSourceEditorViewController: WKComponentViewController {
    
    // MARK: - Properties
    
    private let viewModel: WKSourceEditorViewModel
    private weak var delegate: WKSourceEditorViewControllerDelegate?
    
    private var editorView: WKSourceEditorView {
        return view as! WKSourceEditorView
    }
    
    // MARK: - Lifecycle
    
    public init(viewModel: WKSourceEditorViewModel, delegate: WKSourceEditorViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        self.view = WKSourceEditorView(delegate: self)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        editorView.setup(viewModel: viewModel)
        editorView.inputAccessoryViewType = .expanding
    }
    
    // MARK: - Public
    
    public func closeFind() {
        editorView.closeFind()
        editorView.inputAccessoryViewType = .expanding
    }
    
    public func toggleSyntaxHighlighting() {
        viewModel.isSyntaxHighlightingEnabled.toggle()
        editorView.update(viewModel: viewModel)
    }
    
    // MARK: - Private
    
    private func postUpdateButtonSelectionStatesNotification(withDelay delay: Bool) {
        let selectionState = editorView.selectionState()
        if delay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: Notification.WKSourceEditorSelectionState, object: nil, userInfo: [Notification.WKSourceEditorSelectionStateKey: selectionState])
            }
        } else {
            NotificationCenter.default.post(name: Notification.WKSourceEditorSelectionState, object: nil, userInfo: [Notification.WKSourceEditorSelectionStateKey: selectionState])
        }
    }
}

// MARK: - WKSourceEditorViewDelegate

extension WKSourceEditorViewController: WKSourceEditorViewDelegate {
    func editorViewDidTapItalics(editorView: WKSourceEditorView, isSelected: Bool) {
        let action: WKSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        editorView.toggleItalicsFormatting(action: action, in: editorView.textView)
    }
    
    func editorViewDidTapBold(editorView: WKSourceEditorView, isSelected: Bool) {
        let action: WKSourceEditorFormatterButtonAction = isSelected ? .remove : .add
        editorView.toggleBoldFormatting(action: action, in: editorView.textView)
    }
    
    func editorViewTextSelectionDidChange(editorView: WKSourceEditorView, isRangeSelected: Bool) {
        guard editorView.inputViewType == nil else {
            postUpdateButtonSelectionStatesNotification(withDelay: false)
            return
        }
        
        editorView.inputAccessoryViewType = isRangeSelected ? .highlight : .expanding
        postUpdateButtonSelectionStatesNotification(withDelay: false)
    }
    
    func editorViewDidTapFind(editorView: WKSourceEditorView) {
        editorView.inputAccessoryViewType = .find
        delegate?.sourceEditorViewControllerDidTapFind(sourceEditorViewController: self)
    }
    
    func editorViewDidTapFormatText(editorView: WKSourceEditorView) {
        editorView.inputViewType = .main
        postUpdateButtonSelectionStatesNotification(withDelay: true)
    }
    
    func editorViewDidTapFormatHeading(editorView: WKSourceEditorView) {
        editorView.inputViewType = .headerSelect
    }
    
    func editorViewDidTapCloseInputView(editorView: WKSourceEditorView, isRangeSelected: Bool) {
        editorView.inputViewType = nil
        editorView.inputAccessoryViewType = isRangeSelected ? .highlight : .expanding
    }
    
    func editorViewDidTapShowMore(editorView: WKSourceEditorView) {
        editorView.inputViewType = .main
        postUpdateButtonSelectionStatesNotification(withDelay: true)
    }
}

// MARK: NSNotification Names

extension Notification.Name {
    static let WKSourceEditorSelectionState = Notification.Name("WKSourceEditorSelectionState")
}

extension Notification {
    static let WKSourceEditorSelectionState = Notification.Name.WKSourceEditorSelectionState
    static let WKSourceEditorSelectionStateKey = "WKSourceEditorSelectionStateKey"
}
