import Foundation

public struct WidgetCache: Codable {

	// MARK: - Properties

	public var settings: WidgetSettings
	public var featuredContent: WidgetFeaturedContent?

	// MARK: - Public

	public init(settings: WidgetSettings, featuredContent: WidgetFeaturedContent?) {
		self.settings = settings
		self.featuredContent = featuredContent
	}

}
