
import UIKit

protocol TalkPageUpdateDelegate: class {
    func tappedPublish(updateType: TalkPageUpdateViewController.UpdateType, subject: String?, body: String, viewController: TalkPageUpdateViewController)
}

class TalkPageUpdateViewController: ViewController {
    
    enum UpdateType {
        case newDiscussion
        case newReply
    }
    
    weak var delegate: TalkPageUpdateDelegate?
    let updateType: UpdateType
    
    @IBOutlet private var talkPageScrollView: UIScrollView! {
        didSet {
            stackView = TalkPageUpdateStackView.wmf_viewFromClassNib()
            talkPageScrollView.wmf_addSubviewWithConstraintsToEdges(stackView)
            stackView.widthAnchor.constraint(equalTo: talkPageScrollView.widthAnchor).isActive = true
            stackView.delegate = self
        }
    }

    private var stackView: TalkPageUpdateStackView!
    private var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    
    private var publishButton: UIBarButtonItem!

    
    init(type: UpdateType) {
        self.updateType = type
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        scrollView = talkPageScrollView
        
        super.viewDidLoad()

       commonSetup()
        switch updateType {
        case .newDiscussion:
            newDiscussionSetup()
        case .newReply:
            newReplySetup()
        }
    }
    
    private func commonSetup() {
        publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
        publishButton.isEnabled = false
        navigationItem.rightBarButtonItem = publishButton
        navigationBar.updateNavigationItems()
        navigationBar.isBarHidingEnabled = false
        
        stackView.commonSetup()
        
        talkPageScrollView.keyboardDismissMode = .interactive
        backgroundTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedBackground(_:)))
        view.addGestureRecognizer(backgroundTapGestureRecognizer)
    }
    
    @objc private func tappedBackground(_ tapGestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    private func newDiscussionSetup() {
        title = WMFLocalizedString("talk-page-new-discussion-title", value: "New discussion", comment: "Title of page when composing a new discussion topic on talk pages.")
        
        stackView.newDiscussionSetup()
    }
    
    private func newReplySetup() {
        stackView.newReplySetup()
    }
    
    @objc private func evaluatePublishButtonState() {
        switch updateType {
        case .newDiscussion:
            publishButton.isEnabled = (stackView.subjectTextField.text?.count ?? 0) > 0 && (stackView.bodyTextView.text?.count ?? 0) > 0
        case .newReply:
            publishButton.isEnabled = (stackView.bodyTextView.text?.count ?? 0) > 0
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        guard let subjectText = stackView.subjectTextField.text,
            let bodyText = stackView.bodyTextView.text else {
                return
        }
        
        delegate?.tappedPublish(updateType: .newDiscussion, subject: subjectText, body: bodyText, viewController: self)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        stackView.apply(theme: theme)
        super.apply(theme: theme)
    }
}

extension TalkPageUpdateViewController: TalkPageUpdateStackViewDelegate {
    func textDidChange() {
        evaluatePublishButtonState()
    }
}
