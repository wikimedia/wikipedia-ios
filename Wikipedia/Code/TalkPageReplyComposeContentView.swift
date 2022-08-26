import UIKit
import WMF

class TalkPageReplyComposeContentView: SetupView {
    private lazy var replyTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func setup() {
        addSubview(replyTextView)
        
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: replyTextView.topAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: replyTextView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: replyTextView.bottomAnchor),
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: replyTextView.leadingAnchor)
        ])
    }
}

extension TalkPageReplyComposeContentView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        replyTextView.backgroundColor = theme.colors.paperBackground
        replyTextView.textColor = theme.colors.primaryText
    }
}
