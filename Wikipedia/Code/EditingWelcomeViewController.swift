import UIKit

@objc(WMFEditingWelcomeViewController)
final class EditingWelcomeViewController: WelcomeViewController {
    private let beBoldDataSource = BeBoldDataSource()
    private let impartialToneDataSource = ImpartialToneDataSource()
    private let citeReliableSourcesDataSource = CiteReliableSourcesDataSource()
    private let setKnowledgeFreeDataSource = SetKnowledgeFreeDataSource()

    @objc init(theme: Theme, completion: @escaping () -> Void) {
        super.init(theme: theme, viewControllers: [
            WelcomeContainerViewController(dataSource: beBoldDataSource),
            WelcomeContainerViewController(dataSource: impartialToneDataSource),
            WelcomeContainerViewController(dataSource: citeReliableSourcesDataSource),
            WelcomeContainerViewController(dataSource: setKnowledgeFreeDataSource)
        ], completion: completion)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Be bold

final fileprivate class BeBoldDataSource: WelcomeContainerViewControllerDataSource {
    let isFirst = true

    private let editAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/be-bold/edit", start: CGPoint(x: 59, y: 159), insertBelow: false)
    private let plusesAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/be-bold/pluses")

    lazy var animationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImageNamed: "editing-welcome/be-bold/article", animatedImageViews: [editAnimatedImageView, plusesAnimatedImageView], propertyAnimator: propertyAnimator)
    }()

    private lazy var propertyAnimator: UIViewPropertyAnimator = {
        let editPropertyAnimator = UIViewPropertyAnimator(duration: 0.8, curve: .easeInOut) {
            self.editAnimatedImageView.alpha = 1
        }

        editPropertyAnimator.addAnimations({
            self.plusesAnimatedImageView.alpha = 1
        }, delayFactor: 0.6)

        return editPropertyAnimator
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = WMFLocalizedString("editing-welcome-be-bold-subtitle", value: "Be bold but not reckless in updating articles. Do not agonize over making mistakes: every past version of a page is saved, so mistakes can be easily corrected by our community.", comment: "Subtitle for editing onboarding screen encouraging users to start editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-be-bold-title", value: "Your voice is important", comment: "Title for editing onboarding screen encouraging users to start editing Wikipedia articles"), actionLabelText: CommonStrings.welcomePromiseTitle, actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Write in an impartial tone

final fileprivate class ImpartialToneDataSource: WelcomeContainerViewControllerDataSource {
    private let scaleBarAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/impartial-tone/bar", start: CGPoint(x: 73, y: 50), insertBelow: false, initialAlpha: 1)
    private let scaleArticleAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/impartial-tone/article", start: CGPoint(x: 238, y: 61.5), initialAlpha: 1)
    private let scaleSaturnAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/impartial-tone/saturn", start: CGPoint(x: 40, y: 61.5), initialAlpha: 1)
    private let plusesAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/impartial-tone/pluses")

    lazy var animationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImageNamed: "editing-welcome/impartial-tone/stem", animatedImageViews: [scaleBarAnimatedImageView, scaleArticleAnimatedImageView, scaleSaturnAnimatedImageView, plusesAnimatedImageView], propertyAnimator: propertyAnimator)
    }()

    private lazy var propertyAnimator: UIViewPropertyAnimator = {
        let scalePropertyAnimator = UIViewPropertyAnimator(duration: 2.6, curve: .linear)

        scalePropertyAnimator.addAnimations {
            self.scaleBarAnimatedImageView.transform = CGAffineTransform(rotationAngle: 15 * (.pi / 180))
            let scaleSaturnTranslationY = 0 - self.scaleBarAnimatedImageView.bounds.height * self.scaleBarAnimatedImageView.transform.a
            let scaleArticleTranslationY = self.scaleBarAnimatedImageView.bounds.height * self.scaleBarAnimatedImageView.transform.a
            self.scaleSaturnAnimatedImageView.transform = CGAffineTransform(translationX: 0, y: scaleSaturnTranslationY)
            self.scaleArticleAnimatedImageView.transform = CGAffineTransform(translationX: 0, y: scaleArticleTranslationY)
        }

        scalePropertyAnimator.addAnimations({
            self.scaleBarAnimatedImageView.transform = CGAffineTransform.identity
            self.scaleSaturnAnimatedImageView.transform = CGAffineTransform.identity
            self.scaleArticleAnimatedImageView.transform = CGAffineTransform.identity
        }, delayFactor: 0.7)

        scalePropertyAnimator.addAnimations({
            self.plusesAnimatedImageView.alpha = 1
        }, delayFactor: 2.0)

        return scalePropertyAnimator
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = WMFLocalizedString("editing-welcome-impartial-tone-subtitle", value: "We strive for articles to be written in an impartial tone. When editing, aim to make a fair representation of the world as reliable sources describe it.", comment: "Subtitle for editing onboarding screen instructing users to use impartial tone when editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-impartial-tone-title", value: "Write in an impartial tone", comment: "Title for editing onboarding screen instructing users to use impartial tone when editing Wikipedia articles"), actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Cite reliable sources

final fileprivate class CiteReliableSourcesDataSource: WelcomeContainerViewControllerDataSource {
    private let highlightAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/cite/highlight", start: CGPoint(x: 187, y: 96), insertBelow: false)
    private let plusesAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/cite/pluses")

    lazy var animationView: WelcomeAnimationView = {
        return WelcomeAnimationView(staticImageNamed: "editing-welcome/cite/article", animatedImageViews: [highlightAnimatedImageView, plusesAnimatedImageView], propertyAnimator: propertyAnimator)
    }()

    private lazy var propertyAnimator: UIViewPropertyAnimator = {
        let highlightPropertyAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeInOut)

        highlightPropertyAnimator.addAnimations({
            self.highlightAnimatedImageView.alpha = 1
        }, delayFactor: 0.6)

        let plusesPropertyAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.plusesAnimatedImageView.alpha = 1
        }

        highlightPropertyAnimator.addCompletion { _ in
            plusesPropertyAnimator.startAnimation()
        }

        return highlightPropertyAnimator
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = WMFLocalizedString("editing-welcome-citations-subtitle", value: "All content must be verifiable. When adding new information to an article, editors should provide an inline citation to a reliable source that directly supports the contribution.", comment: "Subtitle for editing onboarding screen instructing users to cite reliable sources when editing Wikipedia articles")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-citations-title", value: "Cite reliable sources", comment: "Title for editing onboarding screen instructing users to cite reliable sources when editing Wikipedia articles"), actionLabelText: nil, actionButtonTitle: nil, contentViewController: contentViewController)
    }()
}

// MARK: Set knowledge free

final fileprivate class SetKnowledgeFreeDataSource: WelcomeContainerViewControllerDataSource {
    private let plusesAnimatedImageView = WelcomeAnimatedImageView(imageName: "editing-welcome/set-knowledge-free/pluses")

    private lazy var articleAnimatedImageViews: [WelcomeAnimatedImageView] = {
        let namePrefix = "editing-welcome/set-knowledge-free/article-"
        let origin = CGPoint(x: 153, y: 85)
        return [
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 200, y: 118)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 104, y: 25)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 111, y: 144)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 122, y: 93)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)14", start: origin, destination: CGPoint(x: 156, y: 62)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 139, y: 55)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 176, y: 26)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 225, y: 24)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)15", start: origin, destination: CGPoint(x: 213, y: 30)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)11", start: origin, destination: CGPoint(x: 167, y: 119)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)16", start: origin, destination: CGPoint(x: 136, y: 167)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)14", start: origin, destination: CGPoint(x: 163, y: 136)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)14", start: origin, destination: CGPoint(x: 55, y: 92)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)15", start: origin, destination: CGPoint(x: 113, y: 113)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)13", start: origin, destination: CGPoint(x: 51, y: 26)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)2", start: origin, destination: CGPoint(x: 225, y: 47)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)12", start: origin, destination: CGPoint(x: 45, y: 67)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)11", start: origin, destination: CGPoint(x: 93, y: 29)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)13", start: origin, destination: CGPoint(x: 162, y: 33)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)9", start: origin, destination: CGPoint(x: 226, y: 31)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)8", start: origin, destination: CGPoint(x: 81, y: 79)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)11", start: origin, destination: CGPoint(x: 223, y: 106)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)6", start: origin, destination: CGPoint(x: 236, y: 85)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)5", start: origin, destination: CGPoint(x: 108, y: 68)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)4", start: origin, destination: CGPoint(x: 184, y: 95)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)3", start: origin, destination: CGPoint(x: 188, y: 51)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)2", start: origin, destination: CGPoint(x: 154, y: 160)),
            WelcomeAnimatedImageView(imageName: "\(namePrefix)14", start: origin, destination: CGPoint(x: 76, y: 126))
        ]
    }()

    lazy var animationView: WelcomeAnimationView = {
        let animatedImageViews = articleAnimatedImageViews + [plusesAnimatedImageView]
        return WelcomeAnimationView(staticImageNamed: "editing-welcome/set-knowledge-free/main-article", animatedImageViews: animatedImageViews, propertyAnimator: propertyAnimator)
    }()

    private lazy var propertyAnimator: UIViewPropertyAnimator = {
        let articlePropertyAnimator = UIViewPropertyAnimator(duration: 0.8, curve: .easeInOut)

        articlePropertyAnimator.addAnimations {
            for imageView in self.articleAnimatedImageViews {
                guard let destination = imageView.normalizedDestination else {
                    continue
                }
                imageView.alpha = 1
                imageView.frame.origin = destination
            }
        }

        let plusesPropertyAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
            self.plusesAnimatedImageView.alpha = 1
        }

        articlePropertyAnimator.addCompletion { _ in
            plusesPropertyAnimator.startAnimation()
        }

        return articlePropertyAnimator
    }()

    lazy var panelViewController: WelcomePanelViewController = {
        let contentText = WMFLocalizedString("editing-welcome-set-knowledge-free-subtitle", value: "In order to give everyone access to the world’s knowledge, we need you to participate in its creation by reading, editing, and contributing to the topics that matter most to you.", comment: "Title for editing onboarding screen encouraging users to participate in the creation of Wikipedia content")
        let contentViewController = WelcomePanelLabelContentViewController(text: contentText)
        return WelcomePanelViewController(titleLabelText: WMFLocalizedString("editing-welcome-set-knowledge-free-title", value: "Set knowledge free", comment: "Title for editing onboarding screen encouraging users to participate in the creation of Wikipedia content"), actionLabelText: nil, actionButtonTitle: CommonStrings.getStartedTitle, contentViewController: contentViewController)
    }()
}

