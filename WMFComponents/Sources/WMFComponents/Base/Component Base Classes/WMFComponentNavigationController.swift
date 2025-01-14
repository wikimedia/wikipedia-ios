import UIKit
import Combine

open class WMFComponentNavigationController: UINavigationController {

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Properties

    var appEnvironment: WMFAppEnvironment {
        return WMFAppEnvironment.current
    }

    var theme: WMFTheme {
        return WMFAppEnvironment.current.theme
    }
    
    var forcePortrait = false

    // MARK: - Public
    
    @objc public convenience init(rootViewController: UIViewController, modalPresentationStyle: UIModalPresentationStyle) {
        self.init(rootViewController: rootViewController)
        self.modalPresentationStyle = modalPresentationStyle
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        subscribeToAppEnvironmentChanges()
        setup()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setBarAppearance()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return forcePortrait ? .portrait : topViewController?.supportedInterfaceOrientations ?? .all
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
    
    public func turnOnForcePortrait() {
        forcePortrait = true
    }
    
    public func turnOffForcePortrait() {
        forcePortrait = false
    }
    
    // MARK: - AppEnvironment Subscription

    private func subscribeToAppEnvironmentChanges() {
        WMFAppEnvironment.publisher
            .sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
            .store(in: &cancellables)
    }

    // MARK: - Subclass Overrides

    public func appEnvironmentDidChange() {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        setBarAppearance()
    }
    
    private func setBarAppearance() {
        
        return

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithOpaqueBackground()
        barAppearance.largeTitleTextAttributes = [.font: WMFFont.navigationBarLeadingLargeTitleFont]
        
        if modalPresentationStyle == .pageSheet {
            barAppearance.backgroundColor = theme.midBackground
            let backgroundImage = UIImage.roundedRectImage(with: theme.midBackground, cornerRadius: 1)
            barAppearance.backgroundImage = backgroundImage
        } else {
            barAppearance.backgroundColor = theme.paperBackground
            let backgroundImage = UIImage.roundedRectImage(with: theme.paperBackground, cornerRadius: 1)
            barAppearance.backgroundImage = backgroundImage
        }
        
        barAppearance.shadowImage = UIImage()
        barAppearance.shadowColor = .clear
        
        navigationBar.tintColor = theme.navigationBarTintColor
        navigationBar.standardAppearance = barAppearance
        navigationBar.scrollEdgeAppearance = barAppearance
        navigationBar.compactAppearance = barAppearance
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
    
    // MARK: - Private
    
    private func setup() {
        interactivePopGestureRecognizer?.delegate = self
    }

}

extension WMFComponentNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 0
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return false
        }
        
        return true
    }
}
