import SwiftUI
import Combine

/// SwiftUI `View` via `UIHostingController` based Component
open class WMFComponentHostingController<HostedView: View>: UIHostingController<HostedView> {

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

    public override init(rootView: HostedView) {
        super.init(rootView: rootView)
        subscribeToAppEnvironmentChanges()
        setup()
    }

    public override init?(coder aDecoder: NSCoder, rootView: HostedView) {
        super.init(coder: aDecoder, rootView: rootView)
        subscribeToAppEnvironmentChanges()
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        subscribeToAppEnvironmentChanges()
        setup()
    }

    // MARK: - Lifecycle

    private func setup() {
        
    }

    // MARK: - WMFAppEnvironment Subscription

    private func subscribeToAppEnvironmentChanges() {
        WMFAppEnvironment.publisher
            .sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
            .store(in: &cancellables)
    }

    // MARK: - Subclass Overrides

    public func appEnvironmentDidChange() {
        overrideUserInterfaceStyle = appEnvironment.theme.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()
    }

    // Explicitly nonisolated (matching UIHostingController's own deinit) rather than
    // the isolated deinit this class would implicitly get under the module's default
    // MainActor isolation. Works around a swift-frontend 6.3.3 crash: the SIL
    // performance inliner segfaults optimizing the implicit isolated deinit of this
    // generic class in Test configuration builds (-O + default CMO + coverage).
    // The stored properties released here (cancellables) are safe to release from
    // any thread. Revisit when the toolchain fixes the inliner crash.
    nonisolated deinit {
    }

}
