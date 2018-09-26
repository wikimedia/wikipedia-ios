class WMFWelcomeAnimationViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro
    private var hasAlreadyAnimated = false
    
    private(set) var animationView: WMFWelcomeAnimationView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let animationView = animationView else {
            return
        }
        view.wmf_addSubviewWithConstraintsToEdges(animationView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!hasAlreadyAnimated) {
            guard let animationView = animationView else {
                return
            }
            animationView.beginAnimations()
        }
        hasAlreadyAnimated = true
    }
}

class WMFWelcomeAnimationForgroundViewController: WMFWelcomeAnimationViewController {
    override var animationView: WMFWelcomeAnimationView? {
        return animationViewForWelcomePageType
    }
    private lazy var animationViewForWelcomePageType: WMFWelcomeAnimationView? = {
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
        guard let animationView = animationView else {
            return
        }
        switch welcomePageType {
        case .exploration:
            fallthrough
        case .languages:
            fallthrough
        case .analytics:
            animationView.hasCircleBackground = true
        default:
            break
        }
    }
}

class WMFWelcomeAnimationBackgroundViewController: WMFWelcomeAnimationViewController {
    override var animationView: WMFWelcomeAnimationView? {
        return animationViewForWelcomePageType
    }
    private lazy var animationViewForWelcomePageType: WMFWelcomeAnimationView? = {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wmf_addHorizontalAndVerticalParallax(amount: 12)
    }
}

