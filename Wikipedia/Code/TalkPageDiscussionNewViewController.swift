
import UIKit

protocol TalkPageDiscussionNewDelegate: class {
    func addDiscussion(viewController: TalkPageDiscussionNewViewController)
}

class TalkPageDiscussionNewViewController: ViewController {
    
    weak var delegate: TalkPageDiscussionNewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
        navigationItem.rightBarButtonItem = publishButton
        navigationBar.updateNavigationItems()
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        delegate?.addDiscussion(viewController: self)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}
