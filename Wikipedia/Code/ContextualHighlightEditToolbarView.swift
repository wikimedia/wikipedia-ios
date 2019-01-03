class ContextualHighlightEditToolbarView: EditToolbarView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

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
        delegate?.textFormattingProvidingDidTapBold()
    }

    @IBAction private func toggleItalicSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapItalics()
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextStyleFormatting()
    }

    @IBAction private func removeSelectionFormatting(_ sender: UIButton) {
        //
    }

    @IBAction private func toggleReferenceSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapReference()
    }

    @IBAction private func toggleAnchorSelection(_ sender: UIButton) {
        //
    }

    @IBAction private func toggleUnorderedListSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapUnorderedList()
    }

    @IBAction private func toggleOrderedListSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapOrderedList()
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextFormatting()
    }
}
