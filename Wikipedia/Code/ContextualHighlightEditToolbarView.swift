protocol ContextualHighlightEditToolbarViewDelegate: class {
    func textFormattingTapped(sender: ContextualHighlightEditToolbarView)
    func headerFormattingTapped(sender: ContextualHighlightEditToolbarView)
    func boldTapped(sender: ContextualHighlightEditToolbarView)
    func italicTapped(sender: ContextualHighlightEditToolbarView)
    func removeSelectionFormattingTapped(sender: ContextualHighlightEditToolbarView)
    func referenceTapped(sender: ContextualHighlightEditToolbarView)
    func anchorTapped(sender: ContextualHighlightEditToolbarView)
    func unorderedListTapped(sender: ContextualHighlightEditToolbarView)
    func orderedListTapped(sender: ContextualHighlightEditToolbarView)
}

class ContextualHighlightEditToolbarView: EditToolbarView {
    weak var delegate: ContextualHighlightEditToolbarViewDelegate?

    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!
    @IBOutlet weak var headingButton: TextFormattingButton!

    @IBOutlet weak var removeSelectionFormattingButton: TextFormattingButton!
    @IBOutlet weak var citationButton: TextFormattingButton!
    @IBOutlet weak var linkButton: TextFormattingButton!
    @IBOutlet weak var unorderedListButton: TextFormattingButton!
    @IBOutlet weak var orderedListButton: TextFormattingButton!
    @IBOutlet weak var stackView: UIStackView!

    private func selectButton(type: EditButtonType, ordered: Bool) {
        switch (type) {
        case .bold:
            boldButton.isSelected = true
        case .italic:
            italicButton.isSelected = true
        case .heading:
            headingButton.isSelected = true
        case .link:
            linkButton.isSelected = true
        case .reference:
            citationButton.isSelected = true
        default:
            break
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        removeSelectionFormattingButton.isEnabled = false
        unorderedListButton.isEnabled = false
        orderedListButton.isEnabled = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
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
        delegate?.boldTapped(sender: self)
    }

    @IBAction private func toggleItalicSelection(_ sender: UIButton) {
        delegate?.italicTapped(sender: self)
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.headerFormattingTapped(sender: self)
    }

    @IBAction private func removeSelectionFormatting(_ sender: UIButton) {
        delegate?.removeSelectionFormattingTapped(sender: self)
    }

    @IBAction private func toggleReferenceSelection(_ sender: UIButton) {
        delegate?.referenceTapped(sender: self)
    }

    @IBAction private func toggleAnchorSelection(_ sender: UIButton) {
        delegate?.anchorTapped(sender: self)
    }

    @IBAction private func toggleUnorderedListSelection(_ sender: UIButton) {
        delegate?.unorderedListTapped(sender: self)
    }

    @IBAction private func toggleOrderedListSelection(_ sender: UIButton) {
        delegate?.orderedListTapped(sender: self)
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.textFormattingTapped(sender: self)
    }
}
