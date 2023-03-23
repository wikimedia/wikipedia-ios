import UIKit

class NativeWikitextEditorView: SetupView, Themeable {
    
    private let theme: Theme

    lazy var textView: UITextView = {
        let textView: UITextView
//        if #available(iOS 16.0, *) {
//            textView = UITextView(usingTextLayoutManager: true)
//        } else {
            let textStorage = WMFSyntaxHighlightTextStorage()
            textStorage.theme = theme
            let layoutManager = NSLayoutManager()
            let container = NSTextContainer()
            
            container.widthTracksTextView = true
            
            layoutManager.addTextContainer(container)
            textStorage.addLayoutManager(layoutManager)
              
            // 4
            textView = UITextView(frame: bounds, textContainer: container)
        // }
        
        textView.textContainerInset = .init(top: 16, left: 8, bottom: 16, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.keyboardDismissMode = .interactive
        
        return textView
    }()
    
    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        addSubview(textView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            topAnchor.constraint(equalTo: textView.topAnchor),
            bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])
    }
    
    func apply(theme: Theme) {
        textView.backgroundColor = theme.colors.paperBackground
        (textView.textStorage as? WMFSyntaxHighlightTextStorage)?.apply(theme)
    }
}
