protocol ContextualHighlightEditToolbarViewDelegate: class {
    func contextualHighlightEditToolbarViewDidTapTextFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)

    func contextualHighlightEditToolbarViewDidTapBoldToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapItalicToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapRemoveSelectionFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapReferenceToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapAnchorToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapUnorderedListToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapOrderedListToggleButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
}

class ContextualHighlightEditToolbarView: EditToolbarView {
    weak var delegate: ContextualHighlightEditToolbarViewDelegate?

    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!
    @IBOutlet weak var headingButton: TextFormattingButton!

    private func selectButton(type: EditButtonType, ordered: Bool) {
        switch (type) {
        case .bold:
            boldButton.isSelected = true
        case .italic:
            italicButton.isSelected = true
        case .heading:
            headingButton.isSelected = true
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

    @IBAction private func toggleBoldSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapBoldToggleButton(self, button: sender)
    }

    @IBAction private func toggleItalicSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapItalicToggleButton(self, button: sender)
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(self, button: sender)
    }

    @IBAction private func removeSelectionFormatting(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapRemoveSelectionFormattingButton(self, button: sender)
    }

    @IBAction private func toggleReferenceSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapReferenceToggleButton(self, button: sender)
    }

    @IBAction private func toggleAnchorSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapAnchorToggleButton(self, button: sender)
    }

    @IBAction private func toggleUnorderedListSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapUnorderedListToggleButton(self, button: sender)
    }

    @IBAction private func toggleOrderedListSelection(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapOrderedListToggleButton(self, button: sender)
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapTextFormattingButton(self, button: sender)
    }
}
