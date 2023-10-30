import Foundation
import UIKit

public protocol WKSourceEditorViewControllerDelegate: AnyObject {
    func sourceEditorViewControllerDidTapFind(sourceEditorViewController: WKSourceEditorViewController)
}

public class WKSourceEditorViewController: WKComponentViewController {
    
    // MARK: - Properties
    
    private let viewModel: WKSourceEditorViewModel
    private weak var delegate: WKSourceEditorViewControllerDelegate?
    
    var editorView: WKSourceEditorView {
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

        editorView.setInitialText(viewModel.initialText)
        editorView.inputAccessoryViewType = .expanding
    }
    
    // MARK: - Public
    
    public func closeFind() {
        editorView.closeFind()
        editorView.inputAccessoryViewType = .expanding
    }
}

// MARK: - WKSourceEditorViewDelegate

extension WKSourceEditorViewController: WKSourceEditorViewDelegate {
    func editorViewTextSelectionDidChange(editorView: WKSourceEditorView, isRangeSelected: Bool) {
        guard editorView.inputViewType == nil else {
            return
        }
        
        editorView.inputAccessoryViewType = isRangeSelected ? .highlight : .expanding
    }
    
    func editorViewDidTapFind(editorView: WKSourceEditorView) {
        editorView.inputAccessoryViewType = .find
        delegate?.sourceEditorViewControllerDidTapFind(sourceEditorViewController: self)
    }
    
    func editorViewDidTapFormatText(editorView: WKSourceEditorView) {
        editorView.inputViewType = .main
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
    }
}
