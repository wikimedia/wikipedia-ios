
import UIKit

//todo: combine these into 1 view controller & one controller

@objc(WMFTalkPageTopicHintViewController)
class TalkPageTopicHintViewController: HintViewController {
    
    override func configureSubviews() {
        defaultImageView.image = UIImage(named: "published-pencil")
        defaultLabel.text = WMFLocalizedString("talk-page-new-topic-success-text", value: "Your discussion was successfully published", comment: "Banner text that appears after a new discussion was successfully published on a talk page.")
    }
}

@objc(WMFTalkPageReplyHintViewController)
class TalkPageReplyHintViewController: HintViewController {
    
    override func configureSubviews() {
        defaultImageView.image = UIImage(named: "published-pencil")
        defaultLabel.text = WMFLocalizedString("talk-page-new-reply-success-text", value: "Your reply was successfully published", comment: "Banner text that appears after a new reply was successfully published on a talk page discussion.")
    }
}

@objc(WMFTalkPageTopicHintController)
class TalkPageTopicHintController: HintController {
    @objc init() {
        let topicHintViewController = TalkPageTopicHintViewController()
        super.init(hintViewController: topicHintViewController)
    }
    
    override func toggle(presenter: HintPresentingViewController, context: HintController.Context?, theme: Theme) {
        super.toggle(presenter: presenter, context: context, theme: theme)
        setHintHidden(false)
    }
}

@objc(WMFTalkPageReplyHintController)
class TalkPageReplyHintController: HintController {
    @objc init() {
        let topicReplyViewController = TalkPageReplyHintViewController()
        super.init(hintViewController: topicReplyViewController)
    }
    
    override func toggle(presenter: HintPresentingViewController, context: HintController.Context?, theme: Theme) {
        super.toggle(presenter: presenter, context: context, theme: theme)
        setHintHidden(false)
    }
}
