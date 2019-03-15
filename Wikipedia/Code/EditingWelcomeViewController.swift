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
        let contentText = WMFLocalizedString("editing-welcome-be-bold-subtitle", value: "Be bold but not reckless in updating articles. Do not agonize over making mistakes: every past version of a page is saved, so mistakes can be easily corrected by our community.", comment: "Subtitle for editing onboarding screen encouraging users to start editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-be-bold-title", value: "Your voice is important", comment: "Title for editing onboarding screen encouraging users to start editing Wikipedia articles"), actionLabelText: CommonStrings.welcomePromiseTitle, actionButtonTitle: nil, contentViewController: contentViewController)
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
        let contentText = WMFLocalizedString("editing-welcome-impartial-tone-subtitle", value: "We strive for articles to be written in an impartial tone. When editing, aim to make a fair representation of the world as reliable sources describe it.", comment: "Subtitle for editing onboarding screen instructing users to use impartial tone when editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-impartial-tone-title", value: "Write in an impartial tone", comment: "Title for editing onboarding screen instructing users to use impartial tone when editing Wikipedia articles"), actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
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
        let contentText = WMFLocalizedString("editing-welcome-citations-subtitle", value: "All content must be verifiable. When adding new information to an article, editors should provide an inline citation to a reliable source that directly supports the contribution.", comment: "Subtitle for editing onboarding screen instructing users to cite reliable sources when editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-citations-title", value: "Cite reliable sources", comment: "Title for editing onboarding screen instructing users to cite reliable sources when editing Wikipedia articles"), actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
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
        let contentText = WMFLocalizedString("editing-welcome-set-knowledge-free-subtitle", value: "In order to give everyone access to the world’s knowledge, we need you to participate in its creation by reading, editing, and contributing to the topics that matter most to you.", comment: "Title for editing onboarding screen encouraging users to participate in the creation of Wikipedia content")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-set-knowledge-free-title", value: "Set knowledge free", comment: "Title for editing onboarding screen encouraging users to participate in the creation of Wikipedia content"), actionLabelText: nil, actionButtonTitle: CommonStrings.getStartedTitle, contentViewController: contentViewController)
    }()
}

