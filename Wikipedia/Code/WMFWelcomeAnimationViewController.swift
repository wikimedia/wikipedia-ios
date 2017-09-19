
class WMFWelcomeAnimationViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro
    fileprivate var hasAlreadyAnimated = false

    fileprivate lazy var animationView: WMFWelcomeAnimationView = {
        switch welcomePageType {
        case .intro:
            return WMFWelcomeIntroductionAnimationView()
        case .exploration:
            return WMFWelcomeExplorationAnimationView()
        case .languages:
            return WMFWelcomeLanguagesAnimationView()
        case .analytics:
            return WMFWelcomeAnalyticsAnimationView()
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(animationView)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        // Fix for: http://stackoverflow.com/a/39614714
        view.superview?.layoutIfNeeded()
        
        animationView.addAnimationElementsScaledToCurrentFrameSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!hasAlreadyAnimated) {
            animationView.beginAnimations()
        }
        hasAlreadyAnimated = true
    }
}
