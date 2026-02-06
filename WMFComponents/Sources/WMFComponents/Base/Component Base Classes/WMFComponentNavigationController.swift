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
    
    private let customBarBackgroundColor: UIColor?
    
    var forcePortrait = false

    // MARK: - Public
    
    @objc public init(rootViewController: UIViewController, modalPresentationStyle: UIModalPresentationStyle, customBarBackgroundColor: UIColor? = nil) {
        self.customBarBackgroundColor = customBarBackgroundColor
        super.init(rootViewController: rootViewController)
        self.modalPresentationStyle = modalPresentationStyle
        subscribeToAppEnvironmentChanges()
        setup()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setBarAppearance(customLargeTitleFont: self.customLargeTitleFont)
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

        setBarAppearance(customLargeTitleFont: customLargeTitleFont)
    }
    
    private var customLargeTitleFont: UIFont?

    func setBarAppearance(customLargeTitleFont: UIFont?) {
        applySystemGlassAppearance(customLargeTitleFont: customLargeTitleFont)
    }

    private func applySystemGlassAppearance(customLargeTitleFont: UIFont?) {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithDefaultBackground()
        appearance.shadowColor = nil


        let largeTitleFont = self.customLargeTitleFont ?? WMFFont.navigationBarLeadingLargeTitleFont

        if let customLargeTitleFont {
            appearance.largeTitleTextAttributes = [.font: customLargeTitleFont]
        } else {
            appearance.largeTitleTextAttributes = [.font: largeTitleFont]
        }

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        if #available(iOS 18.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }
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
        guard viewControllers.count > 1,
              transitionCoordinator == nil else {
            return false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == interactivePopGestureRecognizer {
            return false
        }
        return true
    }
}
