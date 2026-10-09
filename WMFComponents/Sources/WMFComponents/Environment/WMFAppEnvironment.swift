import UIKit
import Combine
import WMFData

/// An object to communicate app environment changes to all subscribed WMFComponents
@MainActor
public final class WMFAppEnvironment: NSObject, ObservableObject {

	// MARK: - Properties

	@objc public static let current = WMFAppEnvironment()
	public static let publisher = CurrentValueSubject<WMFAppEnvironment, Never>(.current)

    @Published public private(set) var theme = WMFTheme.light
    @Published public private(set) var traitCollection = UITraitCollection.current
    @Published public private(set) var articleAndEditorTextSize: UIContentSizeCategory = .large
	/// Restored before the first screen appears; also exposed to legacy Objective-C presentation controllers.
	@objc @Published public private(set) var isImmersiveModeEnabled = WMFSettingsDataController.shared.immersiveModeEnabled()

	// MARK: - Update

	public func set(theme newTheme: WMFTheme? = nil, articleAndEditorTextSize newArticleAndEditorTextSize: UIContentSizeCategory? = nil, traitCollection newTraitCollection: UITraitCollection? = nil, isImmersiveModeEnabled newIsImmersiveModeEnabled: Bool? = nil) {
		theme = newTheme ?? theme
        articleAndEditorTextSize = newArticleAndEditorTextSize ?? articleAndEditorTextSize
		traitCollection = newTraitCollection ?? traitCollection
		isImmersiveModeEnabled = newIsImmersiveModeEnabled ?? isImmersiveModeEnabled
		WMFAppEnvironment.publisher.send(self)
	}

}
