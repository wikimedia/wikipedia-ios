import Foundation

public struct WidgetFeaturedContent: Codable {

	// MARK: - Nested Types

	enum CodingKeys: String, CodingKey {
		case featuredArticle = "tfa"
        case topRead = "mostread"
        case onThisDay = "onthisday"
        case pictureOfTheDay = "image"
		case fetchDate
		case fetchedLanguageVariantCode
	}

	// MARK: - Properties

	public var featuredArticle: WidgetFeaturedArticle?
    public var topRead: WidgetTopRead?
    public var onThisDay: [WidgetOnThisDayElement]?
    public var pictureOfTheDay: WidgetPictureOfTheDay?

	// MARK: - Properties - Network Fetch Metadata

	public var fetchDate: Date?
	public var fetchedLanguageVariantCode: String?

	// MARK: - Public

	public static func previewContent() -> WidgetFeaturedContent? {
		if let previewContentFilePath = Bundle.main.path(forResource: "Widget Featured Content Preview", ofType: "json"), let jsonData = try? String(contentsOfFile: previewContentFilePath).data(using: .utf8) {
			return try? JSONDecoder().decode(WidgetFeaturedContent.self, from: jsonData)
		}
		
		return nil
	}

}
