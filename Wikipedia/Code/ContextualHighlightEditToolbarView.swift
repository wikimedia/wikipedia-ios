protocol ContextualHighlightEditToolbarViewDelegate: class {
    func contextualHighlightEditToolbarViewDidTapTextFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
}

class ContextualHighlightEditToolbarView: EditToolbarView {
    weak var delegate: ContextualHighlightEditToolbarViewDelegate?

    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!

    private func selectButton(type: EditButtonType, ordered: Bool) {
        switch (type) {
        case .bold:
            boldButton.isSelected = true
        case .italic:
            italicButton.isSelected = true
        default:
            break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorButtonHighlightNotification, object: nil, queue: nil) { [weak self] notification in
            if let message = notification.userInfo?[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChangedSelectedButton] as? ButtonNeedsToBeSelectedMessage {
                self?.selectButton(type: message.type, ordered: message.ordered)
                // print("buttonNeedsToBeSelectedMessage = \(message)")
            }
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(self, button: sender)
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapTextFormattingButton(self, button: sender)
    }
}
