// Version of SectionEditorWebView with hacky testing buttons overlay.
// Only used when testing CodeMirror. May delete later.
// To actually use SectionEditorWebView would need set its selectionChangedDelegate to whatever is responsible for updating button states.

class SectionEditorWebViewWithTestingButtons: SectionEditorWebView {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func testButton(text: String) -> UIButton {
        let button = UIButton()
        let defaultText = NSAttributedString.init(string: text, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11)])
        let selectedText = NSAttributedString.init(string: text, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12)])
        button.setAttributedTitle(defaultText, for: .normal)
        button.setAttributedTitle(selectedText, for: .selected)
        button.setBackgroundImage(UIImage.wmf_image(from: .darkGray), for: .highlighted)
        button.backgroundColor = .lightGray
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.alpha = 0.9
        return button
    }
    
    private let buttonHeight = 16
    
    private lazy var anchorButton: UIButton = {
        let button = testButton(text: "A")
        button.frame = CGRect.init(x: 0, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleAnchorSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var boldButton: UIButton = {
        let button = testButton(text: "B")
        button.frame = CGRect.init(x: 30, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleBoldSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var italicButton: UIButton = {
        let button = testButton(text: "I")
        button.frame = CGRect.init(x: 60, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleItalicSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var unorderedListButton: UIButton = {
        let button = testButton(text: "UL")
        button.frame = CGRect.init(x: 90, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleListSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var orderedListButton: UIButton = {
        let button = testButton(text: "OL")
        button.frame = CGRect.init(x: 120, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleListSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h1Button: UIButton = {
        let button = testButton(text: "H1")
        button.frame = CGRect.init(x: 150, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h2Button: UIButton = {
        let button = testButton(text: "H2")
        button.frame = CGRect.init(x: 180, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h3Button: UIButton = {
        let button = testButton(text: "H3")
        button.frame = CGRect.init(x: 210, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h4Button: UIButton = {
        let button = testButton(text: "H4")
        button.frame = CGRect.init(x: 240, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h5Button: UIButton = {
        let button = testButton(text: "H5")
        button.frame = CGRect.init(x: 270, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var h6Button: UIButton = {
        let button = testButton(text: "H6")
        button.frame = CGRect.init(x: 300, y: 0, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleHeadingSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var referenceButton: UIButton = {
        let button = testButton(text: "Reference")
        button.frame = CGRect.init(x: 0, y: buttonHeight, width: 80, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleReferenceSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var templateButton: UIButton = {
        let button = testButton(text: "Template")
        button.frame = CGRect.init(x: 80, y: buttonHeight, width: 80, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleTemplateSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var indentButton: UIButton = {
        let button = testButton(text: "Indent")
        button.frame = CGRect.init(x: 160, y: buttonHeight, width: 60, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleIndentSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var signatureButton: UIButton = {
        let button = testButton(text: "Signature")
        button.frame = CGRect.init(x: 220, y: buttonHeight, width: 80, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleSignatureSelection(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var cursorLeftButton: UIButton = {
        let button = testButton(text: "←")
        button.frame = CGRect.init(x: 0, y: buttonHeight * 2, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(moveCursorLeft(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var cursorRightButton: UIButton = {
        let button = testButton(text: "→")
        button.frame = CGRect.init(x: 30, y: buttonHeight * 2, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(moveCursorRight(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var cursorUpButton: UIButton = {
        let button = testButton(text: "↑")
        button.frame = CGRect.init(x: 60, y: buttonHeight * 2, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(moveCursorUp(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var cursorDownButton: UIButton = {
        let button = testButton(text: "↓")
        button.frame = CGRect.init(x: 90, y: buttonHeight * 2, width: 30, height: buttonHeight)
        button.addTarget(self, action: #selector(moveCursorDown(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var undoButton: UIButton = {
        let button = testButton(text: "Undo")
        button.frame = CGRect.init(x: 120, y: buttonHeight * 2, width: 60, height: buttonHeight)
        button.addTarget(self, action: #selector(undo(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var redoButton: UIButton = {
        let button = testButton(text: "Redo")
        button.frame = CGRect.init(x: 180, y: buttonHeight * 2, width: 60, height: buttonHeight)
        button.addTarget(self, action: #selector(redo(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var commentButton: UIButton = {
        let button = testButton(text: "Comment")
        button.frame = CGRect.init(x: 240, y: buttonHeight * 2, width: 80, height: buttonHeight)
        button.addTarget(self, action: #selector(toggleComment(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var testTextView: UITextView = {
        let textView = UITextView()
        textView.frame = CGRect.init(x: 0, y: buttonHeight * 3, width: 300, height: buttonHeight * 2)
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1
        textView.text = "Tap to test taking first responder from web view."
        return textView
    }()

    override init() {
        super.init()
        
        defer {
            self.selectionChangedDelegate = self
        }
        
        self.addSubview(anchorButton)
        self.addSubview(boldButton)
        self.addSubview(italicButton)
        self.addSubview(unorderedListButton)
        self.addSubview(orderedListButton)
        self.addSubview(h1Button)
        self.addSubview(h2Button)
        self.addSubview(h3Button)
        self.addSubview(h4Button)
        self.addSubview(h5Button)
        self.addSubview(h6Button)
        self.addSubview(referenceButton)
        self.addSubview(templateButton)
        self.addSubview(indentButton)
        self.addSubview(signatureButton)
        self.addSubview(cursorLeftButton)
        self.addSubview(cursorRightButton)
        self.addSubview(cursorUpButton)
        self.addSubview(cursorDownButton)
        self.addSubview(undoButton)
        self.addSubview(redoButton)
        self.addSubview(commentButton)
        self.addSubview(testTextView)
    }
}

extension SectionEditorWebViewWithTestingButtons: SectionEditorWebViewSelectionChangedDelegate {
    func turnOffAllButtonHighlights() {
        anchorButton.isSelected = false
        boldButton.isSelected = false
        italicButton.isSelected = false
        unorderedListButton.isSelected = false
        orderedListButton.isSelected = false
        h1Button.isSelected = false
        h2Button.isSelected = false
        h3Button.isSelected = false
        h4Button.isSelected = false
        h5Button.isSelected = false
        h6Button.isSelected = false
        templateButton.isSelected = false
        referenceButton.isSelected = false
        indentButton.isSelected = false
        signatureButton.isSelected = false
        undoButton.isSelected = false
        redoButton.isSelected = false
        commentButton.isSelected = false
    }
    
    func highlightBoldButton() {
        boldButton.isSelected = true
    }
    
    func highlightItalicButton() {
        italicButton.isSelected = true
    }
    
    func highlightReferenceButton() {
        referenceButton.isSelected = true
    }
    
    func highlightTemplateButton() {
        templateButton.isSelected = true
    }
    
    func highlightAnchorButton() {
        anchorButton.isSelected = true
    }
    
    func highlightIndentButton(depth: Int) {
        indentButton.isSelected = true
    }
    
    func highlightSignatureButton(depth: Int) {
        signatureButton.isSelected = true
    }
    
    func highlightListButton(ordered: Bool, depth: Int) {
        if ordered {
            orderedListButton.isSelected = true
        } else {
            unorderedListButton.isSelected = true
        }
    }
    
    func highlightHeadingButton(depth: Int) {
        switch depth as Int {
        case 1:
            h1Button.isSelected = true
        case 2:
            h2Button.isSelected = true
        case 3:
            h3Button.isSelected = true
        case 4:
            h4Button.isSelected = true
        case 5:
            h5Button.isSelected = true
        case 6:
            h6Button.isSelected = true
        default:
            break
        }
    }
    
    func highlightUndoButton() {
        undoButton.isSelected = true
    }

    func highlightRedoButton() {
        redoButton.isSelected = true
    }

    func highlightCommentButton() {
        commentButton.isSelected = true
    }
}
