import UIKit

class NativeWikitextEditorView: SetupView {

    lazy var textView: UITextView = {
        let textView: UITextView
        if #available(iOS 16.0, *) {
            textView = UITextView(usingTextLayoutManager: true)
        } else {
            let textStorage = WMFSyntaxHighlightTextStorage()
            let layoutManager = NSLayoutManager()
            let container = NSTextContainer()
            
            container.widthTracksTextView = true
            container.lineFragmentPadding = .zero
            
            layoutManager.addTextContainer(container)
            textStorage.addLayoutManager(layoutManager)
              
            // 4
            textView = UITextView(frame: bounds, textContainer: container)
        }
        
        // textView.textContainerInset = .zero
        // textView.textContainer.lineFragmentPadding = 0
        // textView.automaticallyAdjustsScrollIndicatorInsets = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.keyboardDismissMode = .interactive
        
        return textView
    }()
    
    override func setup() {
        addSubview(textView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            topAnchor.constraint(equalTo: textView.topAnchor),
            bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])
    }
}
