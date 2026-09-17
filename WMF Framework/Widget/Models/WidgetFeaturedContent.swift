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

    /// The independently decoded parts of the feed response. Raw values are the JSON keys.
    public enum Section: String, Codable, CaseIterable {
        case featuredArticle = "tfa"
        case topRead = "mostread"
        case onThisDay = "onthisday"
        case pictureOfTheDay = "image"
    }

	// MARK: - Properties

	public var featuredArticle: WidgetFeaturedArticle?
    public var topRead: WidgetTopRead?
    public var onThisDay: [WidgetOnThisDayElement]?
    public var pictureOfTheDay: WidgetPictureOfTheDay?

	// MARK: - Properties - Network Fetch Metadata

	public var fetchDate: Date?
	public var fetchedLanguageVariantCode: String?

    // MARK: - Properties - Runtime Only (excluded from `CodingKeys`)

    /// One entry per section that was present in the JSON but failed to decode. The section is
    /// left nil instead of failing the whole payload.
    public var sectionDecodingErrors: [Section: String] = [:]

    /// Elements dropped by lossy arrays inside the sections, keyed by section.
    public var droppedElementErrors: [Section: [String]] = [:]

    // MARK: - Public

    public init() {}

	public static func previewContent() -> WidgetFeaturedContent? {
		if let previewContentFilePath = Bundle.main.path(forResource: "Widget Featured Content Preview", ofType: "json"), let jsonData = try? String(contentsOfFile: previewContentFilePath).data(using: .utf8) {
			return try? JSONDecoder().decode(WidgetFeaturedContent.self, from: jsonData)
		}
		
		return nil
	}

    public func hasContent(for section: Section) -> Bool {
        switch section {
        case .featuredArticle:
            return featuredArticle != nil
        case .topRead:
            return topRead != nil
        case .onThisDay:
            return onThisDay != nil
        case .pictureOfTheDay:
            return pictureOfTheDay != nil
        }
    }

}

// MARK: - Decoding

extension WidgetFeaturedContent {

    /// Each section is decoded on its own: a malformed `image` no longer takes the featured
    /// article and top read down with it. Failures are recorded in `sectionDecodingErrors`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var sectionDecodingErrors: [Section: String] = [:]
        var droppedElementErrors: [Section: [String]] = [:]

        func decodeSection<T: Decodable>(_ type: T.Type, _ section: Section, key: CodingKeys) -> T? {
            do {
                return try container.decodeIfPresent(type, forKey: key)
            } catch {
                sectionDecodingErrors[section] = WidgetDecodingErrorDescription.describe(error)
                return nil
            }
        }

        featuredArticle = decodeSection(WidgetFeaturedArticle.self, .featuredArticle, key: .featuredArticle)
        topRead = decodeSection(WidgetTopRead.self, .topRead, key: .topRead)
        pictureOfTheDay = decodeSection(WidgetPictureOfTheDay.self, .pictureOfTheDay, key: .pictureOfTheDay)

        if let onThisDayArray = decodeSection(WidgetLossyDecodingArray<WidgetOnThisDayElement>.self, .onThisDay, key: .onThisDay) {
            onThisDay = onThisDayArray.elements
            if !onThisDayArray.droppedElementErrors.isEmpty {
                droppedElementErrors[.onThisDay] = onThisDayArray.droppedElementErrors
            }
        }

        if let topReadDroppedElementErrors = topRead?.droppedElementErrors, !topReadDroppedElementErrors.isEmpty {
            droppedElementErrors[.topRead] = topReadDroppedElementErrors
        }

        fetchDate = try container.decodeIfPresent(Date.self, forKey: .fetchDate)
        fetchedLanguageVariantCode = try container.decodeIfPresent(String.self, forKey: .fetchedLanguageVariantCode)

        self.sectionDecodingErrors = sectionDecodingErrors
        self.droppedElementErrors = droppedElementErrors
    }

}
