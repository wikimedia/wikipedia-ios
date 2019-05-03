
import UIKit

class TalkPageReplyNewViewController: ViewController {
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    private let replyButton = ActionButton(frame: .zero)
    
    init(dataStore: MWKDataStore, discussion: TalkPageDiscussion) {
        self.dataStore = dataStore
        self.discussion = discussion
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupReplyButton()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        replyButton.apply(theme: theme)
    } 
}

private extension TalkPageReplyNewViewController {
    func setupReplyButton() {
        replyButton.setTitle(WMFLocalizedString("talk-pages-reply-button-title", value: "Reply to this discussion", comment: "Text displayed in a reply button for replying to a talk page discussion thread."), for: .normal)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(replyButton)
        
        let safeAreaGuide = view.safeAreaLayoutGuide
        let trailingConstraint = replyButton.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaGuide.trailingAnchor, constant: 0)
        let leadingConstraint = replyButton.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaGuide.leadingAnchor, constant: 0)
        trailingConstraint.priority = .required
        leadingConstraint.priority = .required
        replyButton.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            replyButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -15),
            replyButton.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 15),
            leadingConstraint,
            trailingConstraint,
            replyButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor)
        ])
    }
}
