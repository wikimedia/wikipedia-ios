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

    // MARK: - Public
    
    public convenience init(rootViewController: UIViewController, modalPresentationStyle: UIModalPresentationStyle) {
        self.init(rootViewController: rootViewController)
        self.modalPresentationStyle = modalPresentationStyle
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        subscribeToAppEnvironmentChanges()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        // Button colors
        navigationBar.tintColor = theme.link
        
        // Other
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.largeTitleTextAttributes = [.font: WMFFont.for(.boldTitle1)]
        appearance.backgroundColor = theme.paperBackground
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }

}
