import UIKit
import Combine

/// UIKit `UIViewController` based Component
open class WKComponentViewController: UIViewController {

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

	public init() {
		super.init(nibName: nil, bundle: nil)
		subscribeToAppEnvironmentChanges()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		subscribeToAppEnvironmentChanges()
	}

	// MARK: - AppEnvironment Subscription

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
