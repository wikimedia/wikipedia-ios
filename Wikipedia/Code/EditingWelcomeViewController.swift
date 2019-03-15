import UIKit

@objc(WMFEditingWelcomeViewController)
final class EditingWelcomeViewController: WelcomeViewController {
    private let beBoldDataSource = BeBoldDataSource()
    private let impartialToneDataSource = ImpartialToneDataSource()
    private let citeReliableSources = CiteReliableSourcesDataSource()
    private let setKnowledgeFreeDataSource = SetKnowledgeFreeDataSource()

    @objc init(theme: Theme) {
        super.init(theme: theme, viewControllers: [
            WelcomeContainerViewController(dataSource: beBoldDataSource),
            WelcomeContainerViewController(dataSource: impartialToneDataSource),
            WelcomeContainerViewController(dataSource: citeReliableSources),
            WelcomeContainerViewController(dataSource: setKnowledgeFreeDataSource)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Be bold

final fileprivate class BeBoldDataSource: WelcomeContainerViewControllerDataSource {
    lazy var foregroundAnimationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImage: UIImage(named: "editing-welcome-article")!)
    }()

    lazy var backgroundAnimationView: WelcomeAnimationView? = {
        return nil
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = "Be bold but not reckless in updating articles. Do not agonize over making mistakes: every past version of a page is saved, so mistakes can be easily corrected by our community."
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: "Be bold", actionLabelText: "By starting, I promise not to misuse this feature", actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Write in an impartial tone

final fileprivate class ImpartialToneDataSource: WelcomeContainerViewControllerDataSource {
    lazy var foregroundAnimationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImage: UIImage(named: "editing-welcome-scale")!)
    }()

    lazy var backgroundAnimationView: WelcomeAnimationView? = {
        return nil
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = "We strive for articles to be written in an impartial tone. When editing, aim to make a fair representation of the world as reliable sources describe it."
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: "Write in an impartial tone", actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Cite reliable sources

final fileprivate class CiteReliableSourcesDataSource: WelcomeContainerViewControllerDataSource {
    lazy var foregroundAnimationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImage: UIImage(named: "editing-welcome-citation")!)
    }()

    lazy var backgroundAnimationView: WelcomeAnimationView? = {
        return nil
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = "All content must be verifiable. When adding new information to an article, editors should provide an inline citation to a reliable source that directly supports the contribution."
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: "Cite reliable sources", actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Set knowledge free

final fileprivate class SetKnowledgeFreeDataSource: WelcomeContainerViewControllerDataSource {
    lazy var foregroundAnimationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImage: UIImage(named: "editing-welcome-articles")!)
    }()

    lazy var backgroundAnimationView: WelcomeAnimationView? = {
        return nil
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = "In order to give everyone access to the world’s knowledge, we need you to participate in its creation by reading, editing, and contributing to the topics that matter most to you."
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: "Set knowledge free", actionLabelText: nil, actionButtonTitle: "Get started", contentViewController: contentViewController)
    }()
}

