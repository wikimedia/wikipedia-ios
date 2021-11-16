import Foundation

public struct PushNotificationsSettings: Codable {

    // MARK: - Properties

    public static let `default` = PushNotificationsSettings(primaryLanguageCode: "en", primaryLanguageVariantCode: nil)

    public let primaryLanguageCode: String
    public let primaryLanguageVariantCode: String?

    // MARK: - Public

    public init(primaryLanguageCode: String, primaryLanguageVariantCode: String?) {
        self.primaryLanguageCode = primaryLanguageCode
        self.primaryLanguageVariantCode = primaryLanguageVariantCode
    }

}
