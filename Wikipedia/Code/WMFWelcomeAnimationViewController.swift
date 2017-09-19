
class WMFWelcomeAnimationViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro
    fileprivate var hasAlreadyAnimated = false

    fileprivate lazy var animationView: WMFWelcomeAnimationView = {
        switch self.welcomePageType {
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
        view.addSubview(animationView)

        animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        animationView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
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
