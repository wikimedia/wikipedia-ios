import Foundation

public struct AgentData: Encodable {
    public var appFlavor: String?
    public var appInstallId: String?
    public var appTheme: String?
    public var appVersion: Int?
    public var appVersionName: String?
    public var clientPlatform: String?
    public var clientPlatformFamily: String?
    public var deviceFamily: String?
    public var deviceLanguage: String?
    public var releaseStatus: String?

    public init(
        appFlavor: String? = nil,
        appInstallId: String? = nil,
        appTheme: String? = nil,
        appVersion: Int? = nil,
        appVersionName: String? = nil,
        clientPlatform: String? = nil,
        clientPlatformFamily: String? = nil,
        deviceFamily: String? = nil,
        deviceLanguage: String? = nil,
        releaseStatus: String? = nil
    ) {
        self.appFlavor = appFlavor
        self.appInstallId = appInstallId
        self.appTheme = appTheme
        self.appVersion = appVersion
        self.appVersionName = appVersionName
        self.clientPlatform = clientPlatform
        self.clientPlatformFamily = clientPlatformFamily
        self.deviceFamily = deviceFamily
        self.deviceLanguage = deviceLanguage
        self.releaseStatus = releaseStatus
    }

    enum CodingKeys: String, CodingKey {
        case appFlavor = "app_flavor"
        case appInstallId = "app_install_id"
        case appTheme = "app_theme"
        case appVersion = "app_version"
        case appVersionName = "app_version_name"
        case clientPlatform = "client_platform"
        case clientPlatformFamily = "client_platform_family"
        case deviceFamily = "device_family"
        case deviceLanguage = "device_language"
        case releaseStatus = "release_status"
    }
}
