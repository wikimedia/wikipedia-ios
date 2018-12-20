class TextFormattingToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBOutlet var buttons: [TextFormattingButton]!
    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!
    @IBOutlet weak var citationButton: TextFormattingButton!
    @IBOutlet weak var templateButton: TextFormattingButton!
    @IBOutlet weak var exclamationButton: TextFormattingButton!
    @IBOutlet weak var linkButton: TextFormattingButton!

    @IBAction private func toggleBold(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapBoldButton(self, button: sender)
    }

    @IBAction private func toggleItalics(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapItalicsButton(self, button: sender)
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
        case .reference:
            citationButton.isSelected = true
        case .template:
            templateButton.isSelected = true
        case .link:
            linkButton.isSelected = true
        default:
            print("button type not yet handled: \(type)")
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
