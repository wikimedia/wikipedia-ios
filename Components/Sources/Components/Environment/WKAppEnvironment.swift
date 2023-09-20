import UIKit
import Combine

/// An object to communicate app environment changes to all subscribed Components
public final class WKAppEnvironment: ObservableObject {

	// MARK: - Properties

	public static let current = WKAppEnvironment()
	public static let publisher = CurrentValueSubject<WKAppEnvironment, Never>(.current)

	@Published public private(set) var theme = WKTheme.light
	@Published public private(set) var traitCollection = UITraitCollection.current

	// MARK: - Update

	public func set(theme newTheme: WKTheme? = nil, traitCollection newTraitCollection: UITraitCollection? = nil) {
		theme = newTheme ?? theme
		traitCollection = newTraitCollection ?? traitCollection
		WKAppEnvironment.publisher.send(self)
	}

}
