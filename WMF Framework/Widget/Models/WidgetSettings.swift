import Foundation

public struct WidgetSettings: Codable {

	// MARK: - Properties

	public static let `default` = WidgetSettings(siteURL: URL(string: "https://en.wikipedia.org")!, languageCode: "en", languageVariantCode: nil)

	public let siteURL: URL
	public let languageCode: String
	public let languageVariantCode: String?

	// MARK: - Public

	public init(siteURL: URL, languageCode: String, languageVariantCode: String?) {
		self.siteURL = siteURL
		self.languageCode = languageCode
		self.languageVariantCode = languageVariantCode
	}

}
