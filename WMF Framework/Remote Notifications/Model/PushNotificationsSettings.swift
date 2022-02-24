import Foundation

public struct PushNotificationsSettings: Codable {

    // MARK: - Properties

    public static let `default` = PushNotificationsSettings(primaryLanguageCode: "en", primaryLocalizedName: "English", primaryLanguageVariantCode: nil)

    public let primaryLanguageCode: String
    public let primaryLocalizedName: String
    public let primaryLanguageVariantCode: String?

    // MARK: - Public

    public init(primaryLanguageCode: String, primaryLocalizedName: String, primaryLanguageVariantCode: String?) {
        self.primaryLanguageCode = primaryLanguageCode
        self.primaryLocalizedName = primaryLocalizedName
        self.primaryLanguageVariantCode = primaryLanguageVariantCode
    }

}
