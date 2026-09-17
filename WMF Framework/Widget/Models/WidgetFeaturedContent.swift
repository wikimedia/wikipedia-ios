import Foundation

public struct WidgetFeaturedContent: Codable {

	// MARK: - Nested Types

	enum CodingKeys: String, CodingKey {
		case featuredArticle = "tfa"
        case topRead = "mostread"
        case onThisDay = "onthisday"
        case pictureOfTheDay = "image"
		case fetchDate
        case fetchedLanguageCode
		case fetchedLanguageVariantCode
        case staleSections
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
    public var fetchedLanguageCode: String?
	public var fetchedLanguageVariantCode: String?

    /// Sections that did not come from the fetch this content was saved from, but were carried
    /// over from the previous cache so the widget has something to show. A stale section must
    /// not short-circuit the next network fetch.
    public var staleSections: [Section] = []

    // MARK: - Properties - Runtime Only (excluded from `CodingKeys`)

    /// One entry per section that was present in the JSON but failed to decode. The section is
    /// left nil instead of failing the whole payload.
    public var sectionDecodingErrors: [Section: String] = [:]

    /// Elements dropped by lossy arrays inside the sections, keyed by section.
    public var droppedElementErrors: [Section: [String]] = [:]

    /// True when this whole content is being served from the cache because the fetch failed.
    public var isFromCacheFallback: Bool = false

    // MARK: - Public

    public init() {}

	public static func previewContent() -> WidgetFeaturedContent? {
		if let previewContentFilePath = Bundle.main.path(forResource: "Widget Featured Content Preview", ofType: "json"), let jsonData = try? String(contentsOfFile: previewContentFilePath).data(using: .utf8) {
			return try? JSONDecoder().decode(WidgetFeaturedContent.self, from: jsonData)
		}
		
		return nil
	}

    public func isStale(_ section: Section) -> Bool {
        return isFromCacheFallback || staleSections.contains(section)
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

    /// Fills the sections missing from `fresh` with the ones from `cached`, marking them stale.
    /// Sections present in `fresh` always win. `cached` should be for the same language.
    public static func merging(fresh: WidgetFeaturedContent, withCached cached: WidgetFeaturedContent?) -> WidgetFeaturedContent {
        guard let cached = cached else {
            return fresh
        }

        var merged = fresh
        var staleSections: [Section] = []

        for section in Section.allCases where !fresh.hasContent(for: section) && cached.hasContent(for: section) {
            switch section {
            case .featuredArticle:
                merged.featuredArticle = cached.featuredArticle
            case .topRead:
                merged.topRead = cached.topRead
            case .onThisDay:
                merged.onThisDay = cached.onThisDay
            case .pictureOfTheDay:
                merged.pictureOfTheDay = cached.pictureOfTheDay
            }
            staleSections.append(section)
        }

        merged.staleSections = staleSections
        return merged
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
            var onThisDayDroppedElementErrors = onThisDayArray.droppedElementErrors
            for (index, element) in onThisDayArray.elements.enumerated() {
                onThisDayDroppedElementErrors += element.droppedPageErrors.map { "[\(index)].pages\($0)" }
            }
            if !onThisDayDroppedElementErrors.isEmpty {
                droppedElementErrors[.onThisDay] = onThisDayDroppedElementErrors
            }
        }

        if let topReadDroppedElementErrors = topRead?.droppedElementErrors, !topReadDroppedElementErrors.isEmpty {
            droppedElementErrors[.topRead] = topReadDroppedElementErrors
        }

        fetchDate = try container.decodeIfPresent(Date.self, forKey: .fetchDate)
        fetchedLanguageCode = try container.decodeIfPresent(String.self, forKey: .fetchedLanguageCode)
        fetchedLanguageVariantCode = try container.decodeIfPresent(String.self, forKey: .fetchedLanguageVariantCode)
        staleSections = try container.decodeIfPresent([Section].self, forKey: .staleSections) ?? []

        self.sectionDecodingErrors = sectionDecodingErrors
        self.droppedElementErrors = droppedElementErrors
    }

}
