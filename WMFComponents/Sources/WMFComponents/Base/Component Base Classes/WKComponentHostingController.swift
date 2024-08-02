import SwiftUI
import Combine

/// SwiftUI `View` via `UIHostingController` based Component
open class WKComponentHostingController<HostedView: View>: UIHostingController<HostedView> {

	// MARK: - Private Properties

	private var cancellables = Set<AnyCancellable>()

	// MARK: - Public Properties

	var appEnvironment: WKAppEnvironment {
		return WKAppEnvironment.current
	}

	var theme: WKTheme {
		return WKAppEnvironment.current.theme
	}

	// MARK: - Public

	public override init(rootView: HostedView) {
		super.init(rootView: rootView)
		subscribeToAppEnvironmentChanges()
	}

	public override init?(coder aDecoder: NSCoder, rootView: HostedView) {
		super.init(coder: aDecoder, rootView: rootView)
		subscribeToAppEnvironmentChanges()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		subscribeToAppEnvironmentChanges()
	}

	// MARK: - WKAppEnvironment Subscription

	private func subscribeToAppEnvironmentChanges() {
		WKAppEnvironment.publisher
			.sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
			.store(in: &cancellables)
	}

	// MARK: - Subclass Overrides

	public func appEnvironmentDidChange() {
		// Subclasses should implement
	}

}
