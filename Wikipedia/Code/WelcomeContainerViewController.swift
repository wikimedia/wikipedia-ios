import UIKit

protocol WelcomeContainerViewControllerDataSource: AnyObject {
    var animationView: WelcomeAnimationView { get }
    var panelViewController: WelcomePanelViewController { get }
    var isFirst: Bool { get }
}

extension WelcomeContainerViewControllerDataSource {
    var isFirst: Bool {
        return false
    }
}

class WelcomeContainerViewController: UIViewController {
    weak var dataSource: WelcomeContainerViewControllerDataSource?
    
    @IBOutlet private weak var topContainerView: UIView!
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
        addChild(WelcomeAnimationViewController(animationView: dataSource.animationView, waitsForAnimationTrigger: dataSource.isFirst), to: topContainerView)
        addChild(dataSource.panelViewController, to: bottomContainerView)
        apply(theme: theme)
    }
    
    private func addChild(_ viewController: UIViewController?, to view: UIView) {
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
        (viewController as? Themeable)?.apply(theme: theme)
    }
}

extension WelcomeContainerViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        children.forEach { ($0 as? Themeable)?.apply(theme: theme) }
        topContainerView.backgroundColor = theme.colors.midBackground
        bottomContainerView.backgroundColor = theme.colors.midBackground
    }
}

extension WelcomeContainerViewController: PageViewControllerViewLifecycleDelegate {
    func pageViewControllerDidAppear(_ pageViewController: UIPageViewController) {
        dataSource?.animationView.animate()
    }
}
