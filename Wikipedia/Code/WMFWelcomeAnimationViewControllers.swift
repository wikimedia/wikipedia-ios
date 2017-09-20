class WMFWelcomeAnimationViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro
    fileprivate var hasAlreadyAnimated = false
    
    open lazy var animationView: WMFWelcomeAnimationView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let animationView = animationView else {return}
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(animationView)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        view.superview?.layoutIfNeeded() // Fix for: http://stackoverflow.com/a/39614714
        guard let animationView = animationView else {return}
        animationView.addAnimationElementsScaledToCurrentFrameSize()
        // animationView.layer.borderWidth = 1
        // animationView.layer.borderColor = UIColor(0xeeeeee).cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!hasAlreadyAnimated) {
            guard let animationView = animationView else {return}
            animationView.beginAnimations()
        }
        hasAlreadyAnimated = true
    }
}

class WMFWelcomeAnimationForgroundViewController: WMFWelcomeAnimationViewController {
    override lazy var animationView: WMFWelcomeAnimationView? = {
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
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        guard let animationView = animationView else {return}
        switch welcomePageType {
        case .exploration:
            fallthrough
        case .languages:
            fallthrough
        case .analytics:
            animationView.backgroundColor = UIColor(0xdee6f6)
            animationView.layer.cornerRadius = animationView.frame.size.width / 2.0
            animationView.layer.masksToBounds = true
        default:
            // animationView.backgroundColor = UIColor(0xdddddd)
            break
        }
    }
}

class WMFWelcomeAnimationBackgroundViewController: WMFWelcomeAnimationViewController {
    override lazy var animationView: WMFWelcomeAnimationView? = {
        switch welcomePageType {
        case .intro:
            return nil
        case .exploration:
            return WMFWelcomeExplorationAnimationBackgroundView()
        case .languages:
            return WMFWelcomeLanguagesAnimationBackgroundView()
        case .analytics:
            return WMFWelcomeAnalyticsAnimationBackgroundView()
        }
    }()
}

