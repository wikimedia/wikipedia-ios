import Foundation

public struct WidgetFeaturedContent: Codable {

	// MARK: - Nested Types

	enum CodingKeys: String, CodingKey {
		case featuredArticle = "tfa"
		case fetchDate
	}

	public struct FeaturedArticleContent: Codable {

		// MARK: - Featured Article - Nested Types

		enum CodingKeys: String, CodingKey {
			case normalizedTitle = "normalizedtitle"
			case description
			case extract
			case languageCode = "lang"
			case languageDirection = "dir"
			case contentURL = "content_urls"
			case thumbnailImageSource = "thumbnail"
			case originalImageSource = "originalimage"
		}

		public struct ContentURL: Codable {
			public struct PageURL: Codable {
				public let page: String
			}

			public let desktop: PageURL
		}

		public struct ImageSource: Codable {
			enum CodingKeys: String, CodingKey {
				case source
				case width
				case height
				case data
			}

			public let source: String
			public let width: Int
			public let height: Int
			public var data: Data?
		}

		// MARK: - Featured Article - Properties

		public var normalizedTitle: String
		public let description: String?
		public let extract: String
		public let languageCode: String
		public let languageDirection: String
		public let contentURL: ContentURL
		public var thumbnailImageSource: ImageSource?
		public var originalImageSource: ImageSource?
	}

	// MARK: - Properties

	public var fetchDate: Date?
	public var featuredArticle: FeaturedArticleContent?

}
