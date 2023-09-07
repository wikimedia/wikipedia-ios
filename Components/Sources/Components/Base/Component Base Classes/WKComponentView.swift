import UIKit
import Combine

/// UIKit `UIView` based Component
public class WKComponentView: UIView {

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

	public override init(frame: CGRect) {
		super.init(frame: frame)
		translatesAutoresizingMaskIntoConstraints = false
		subscribeToAppEnvironmentChanges()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		translatesAutoresizingMaskIntoConstraints = false
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
