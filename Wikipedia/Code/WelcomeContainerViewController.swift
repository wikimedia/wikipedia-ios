import UIKit

protocol WelcomeContainerViewControllerDataSource: AnyObject {
    var foregroundAnimationView: WelcomeAnimationView { get }
    var backgroundAnimationView: WelcomeAnimationView? { get }
    var panelViewController: WelcomePanelViewController { get }
}

class WelcomeContainerViewController: UIViewController {
    weak var dataSource: WelcomeContainerViewControllerDataSource?
    
    @IBOutlet private weak var topForegroundContainerView: UIView!
    @IBOutlet private weak var topBackgroundContainerView: UIView!
    @IBOutlet private weak var bottomContainerView: UIView!

    private var theme = Theme.standard

    init(dataSource: WelcomeContainerViewControllerDataSource) {
        self.dataSource = dataSource
        super.init(nibName: "WelcomeContainerViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let dataSource = dataSource else {
            assertionFailure("dataSource should be set by now")
            apply(theme: theme)
            return
        }
        addChild(WelcomeAnimationViewController(position: .foreground, animationView: dataSource.foregroundAnimationView), to: topForegroundContainerView)
        if let backgroundAnimationView = dataSource.backgroundAnimationView {
            addChild(WelcomeAnimationViewController(position: .background, animationView: backgroundAnimationView), to: topBackgroundContainerView)
        } else {
            topBackgroundContainerView.isHidden = true
        }
        addChild(dataSource.panelViewController, to: bottomContainerView)
        apply(theme: theme)
    }
    
    private func addChild(_ viewController: (UIViewController & Themeable)?, to view: UIView) {
        guard
            let viewController = viewController,
            viewController.parent == nil,
            viewIfLoaded != nil
        else {
            return
        }
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(viewController.view)
        viewController.didMove(toParent: self)
        viewController.apply(theme: theme)
    }
}

extension WelcomeContainerViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        #warning("Theme WelcomeContainerViewController")
    }
}
