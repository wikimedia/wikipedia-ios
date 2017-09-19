
class WMFWelcomeAnimationBackgroundViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro
    fileprivate var hasAlreadyAnimated = false
    
    fileprivate lazy var backgroundAnimationView: UIView = {
        switch welcomePageType {
        case .intro:
            let view = UIView()
            view.backgroundColor = .red
            return view
        case .exploration:
            let view = UIView()
            view.backgroundColor = .green
            return view
        case .languages:
            let view = UIView()
            view.backgroundColor = .blue
            return view
        case .analytics:
            let view = UIView()
            view.backgroundColor = .yellow
            return view
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundAnimationView.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(backgroundAnimationView)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        view.superview?.layoutIfNeeded() // Fix for: http://stackoverflow.com/a/39614714
//        animationView.addAnimationElementsScaledToCurrentFrameSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!hasAlreadyAnimated) {
//            animationView.beginAnimations()
        }
        hasAlreadyAnimated = true
    }
}
