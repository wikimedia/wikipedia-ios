import Foundation

public struct WidgetSettings: Codable {

    // MARK: - Properties

    public static let `default` = WidgetSettings(siteURL: URL(string: "https://en.wikipedia.org")!, languageCode: "en", languageVariantCode: nil, preferredLanguageCodes: ["en"])

    public let siteURL: URL
    public let languageCode: String
    public let languageVariantCode: String?
    public let preferredLanguageCodes: [String]

    // MARK: - Public

    public init(siteURL: URL, languageCode: String, languageVariantCode: String?, preferredLanguageCodes: [String]) {
        self.siteURL = siteURL
        self.languageCode = languageCode
        self.languageVariantCode = languageVariantCode
        self.preferredLanguageCodes = preferredLanguageCodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        siteURL = try container.decode(URL.self, forKey: .siteURL)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        languageVariantCode = try container.decodeIfPresent(String.self, forKey: .languageVariantCode)
        preferredLanguageCodes = try container.decodeIfPresent([String].self, forKey: .preferredLanguageCodes) ?? [languageCode]
    }
}
