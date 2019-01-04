class TextFormattingGroupedToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBOutlet var buttons: [TextFormattingButton]!
    @IBOutlet weak var indentDecrease: TextFormattingButton!
    @IBOutlet weak var indentIncrease: TextFormattingButton!
    @IBOutlet weak var unorderedList: TextFormattingButton!
    @IBOutlet weak var orderedList: TextFormattingButton!
    @IBOutlet weak var xUp: TextFormattingButton!
    @IBOutlet weak var xDown: TextFormattingButton!
    @IBOutlet weak var underline: TextFormattingButton!
    @IBOutlet weak var strikethrough: TextFormattingButton!
    @IBOutlet weak var stackView: UIStackView!

    
    @IBAction private func increaseIndent(sender: UIButton) {
        delegate?.increaseIndentTapped(sender: self)
    }
    @IBAction private func decreaseIndent(sender: UIButton) {
        delegate?.decreaseIndentTapped(sender: self)
    }
    @IBAction private func toggleUnorderedList(sender: UIButton) {
        delegate?.unorderedListTapped(sender: self)
    }
    @IBAction private func toggleOrderedList(sender: UIButton) {
        delegate?.orderedListTapped(sender: self)
    }
    @IBAction private func toggleSuperscript(sender: UIButton) {
        delegate?.superscriptTapped(sender: self)
    }
    @IBAction private func toggleSubscript(sender: UIButton) {
        delegate?.subscriptTapped(sender: self)
    }
    @IBAction private func toggleUnderline(sender: UIButton) {
        delegate?.underlineTapped(sender: self)
    }
    @IBAction private func toggleStrikethrough(sender: UIButton) {
        delegate?.strikethroughTapped(sender: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.isLayoutMarginsRelativeArrangement = true
    }
    
    private func deselectAllButtons() {
        buttons.forEach() {
            $0.isSelected = false
        }
    }
    
    private func selectButton(type: EditButtonType, ordered: Bool) {
        switch (type) {
        case .superscript:
            xUp.isSelected = true
        case .subscript:
            xDown.isSelected = true
        case .underline:
            underline.isSelected = true
        case .strikethrough:
            strikethrough.isSelected = true
        case .li:
            if ordered {
                orderedList.isSelected = true
            }else{
                unorderedList.isSelected = true
            }
        default:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil, queue: nil) { [weak self] notification in
            self?.deselectAllButtons()
            // if let message = notification.userInfo?[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChanged] as? SelectionChangedMessage {
            //     print("selectionChangedMessage = \(message)")
            // }
        }
        
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
}

extension TextFormattingGroupedToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
