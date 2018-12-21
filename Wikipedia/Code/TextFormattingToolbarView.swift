class TextFormattingToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBOutlet var buttons: [TextFormattingButton]!
    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!
    @IBOutlet weak var citationButton: TextFormattingButton!
    @IBOutlet weak var templateButton: TextFormattingButton!
    @IBOutlet weak var exclamationButton: TextFormattingButton!
    @IBOutlet weak var linkButton: TextFormattingButton!

    @IBAction private func toggleBold(sender: UIButton) {
        delegate?.boldTapped(sender: self)
    }

    @IBAction private func toggleItalics(sender: UIButton) {
        delegate?.italicTapped(sender: self)
    }

    @IBAction private func toggleReference(sender: UIButton) {
        delegate?.referenceTapped(sender: self)
    }

    @IBAction private func toggleTemplate(sender: UIButton) {
        delegate?.templateTapped(sender: self)
    }

    @IBAction private func toggleComment(sender: UIButton) {
        delegate?.commentTapped(sender: self)
    }

    @IBAction private func toggleLink(sender: UIButton) {
        delegate?.linkTapped(sender: self)
    }
    
    private func deselectAllButtons() {
        buttons.forEach() {
            $0.isSelected = false
        }
    }
    
    private func selectButton(type: EditButtonType) {
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

        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil, queue: nil) { [weak self] notification in
            self?.deselectAllButtons()
            // if let message = notification.userInfo?[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChanged] as? SelectionChangedMessage {
            //     print("selectionChangedMessage = \(message)")
            // }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorButtonHighlightNotification, object: nil, queue: nil) { [weak self] notification in
            if let message = notification.userInfo?[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChangedSelectedButton] as? ButtonNeedsToBeSelectedMessage {
                self?.selectButton(type: message.type)
                // print("buttonNeedsToBeSelectedMessage = \(message)")
            }
        }
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension TextFormattingToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
