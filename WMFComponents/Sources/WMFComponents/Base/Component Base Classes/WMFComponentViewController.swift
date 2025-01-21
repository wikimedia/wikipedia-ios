import UIKit
import Combine

/// UIKit `UIViewController` based Component
open class WMFComponentViewController: UIViewController {

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

    public init() {
        super.init(nibName: nil, bundle: nil)
        subscribeToAppEnvironmentChanges()
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        subscribeToAppEnvironmentChanges()
        setup()
    }

    // MARK: - Lifecycle

    private func setup() {
        
    }

    // MARK: - AppEnvironment Subscription

    private func subscribeToAppEnvironmentChanges() {
        WMFAppEnvironment.publisher
        .sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
        .store(in: &cancellables)
    }

    // MARK: - Subclass Overrides

    public func appEnvironmentDidChange() {
        overrideUserInterfaceStyle = appEnvironment.theme.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        // Subclasses should implement
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return appEnvironment.theme.preferredStatusBarStyle
    }

}
