import UIKit


/// Matches the appearance of the launch xib and shows while we do any setup or migrations that need to block user interaction.
/// If this VC is shown for longer than `maximumNonInteractiveTimeInterval`, the view transitions to a loading animation.
@objc (WMFSplashScreenViewController)
class SplashScreenViewController: ThemeableViewController {
    
    // MARK: Object Lifecycle
    
    deinit {
        // Should be canceled on willDisappear, but this is extra insurance
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplashView()
    }
    
    func triggerMigratingAnimation() {
        perform(#selector(showLoadingAnimation), with: nil, afterDelay: SplashScreenViewController.maximumNonInteractiveTimeInterval)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoadingAnimation), object: nil)
    }
    
    /// Ensure we show the busy animation for some minimum amount of time, otherwise the transition can be jarring
    @objc func ensureMinimumShowDuration(completion: @escaping () -> Void) {
        guard loadingAnimationShowTime != 0 else {
            completion()
            return
        }
        let now = CFAbsoluteTimeGetCurrent()
        let busyAnimationVisibleTimeInterval = now - loadingAnimationShowTime
        guard busyAnimationVisibleTimeInterval < SplashScreenViewController.minimumBusyAnimationVisibleTimeInterval else {
            completion()
            return
        }
        let delay = SplashScreenViewController.minimumBusyAnimationVisibleTimeInterval - busyAnimationVisibleTimeInterval
        dispatchOnMainQueueAfterDelayInSeconds(delay, completion)
    }
    
    // MARK: Constants
    
    static let maximumNonInteractiveTimeInterval: TimeInterval = 4
    static let minimumBusyAnimationVisibleTimeInterval: TimeInterval = 0.6
    static let crossFadeAnimationDuration: TimeInterval = 0.3
    
    // MARK: Splash View
    
    func setupSplashView() {
        view.wmf_addSubviewWithConstraintsToEdges(splashView)
        let wordmark = UIImage(named: "splashscreen-wordmark")
        let wordmarkView = UIImageView(image: wordmark)
        wordmarkView.translatesAutoresizingMaskIntoConstraints = false
        splashView.addSubview(wordmarkView)
        let centerXConstraint = splashView.centerXAnchor.constraint(equalTo: wordmarkView.centerXAnchor)
        let centerYConstraint = splashView.centerYAnchor.constraint(equalTo: wordmarkView.centerYAnchor, constant: 12)
        splashView.addConstraints([centerXConstraint, centerYConstraint])
    }
    
    /// Matches launch xib
    lazy var splashView: UIImageView = {
        let splashView = UIImageView()
        splashView.translatesAutoresizingMaskIntoConstraints = false
        splashView.contentMode = .center
        if UI_USER_INTERFACE_IDIOM() != .pad {
            splashView.image = UIImage(named: "splashscreen-background")
        }
        if #available(iOS 13.0, *) {
            splashView.backgroundColor = UIColor.systemBackground
        } else {
            splashView.backgroundColor = UIColor.white
        }
        return splashView
    }()
    
    // MARK: Loading Animation
    
    var loadingAnimationShowTime: CFAbsoluteTime = 0
    
    lazy var loadingAnimationViewController: LoadingAnimationViewController = {
       return LoadingAnimationViewController(nibName: "LoadingAnimationViewController", bundle: nil)
    }()
    
    @objc private func showLoadingAnimation() {
        loadingAnimationShowTime = CFAbsoluteTimeGetCurrent()
        wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: view, belowSubview: splashView)
        UIView.animate(withDuration: SplashScreenViewController.crossFadeAnimationDuration) {
            self.splashView.alpha = 0
        }
    }
    
    //MARK: Themable
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        guard viewIfLoaded != nil else {
            return
        }
        
        loadingAnimationViewController.apply(theme: theme)
    }
}
