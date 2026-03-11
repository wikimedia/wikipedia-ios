import Foundation

public struct ContextValue {
    public static let agentAppInstallId = "agent_app_install_id"
    public static let agentClientPlatform = "agent_client_platform"
    public static let agentClientPlatformFamily = "agent_client_platform_family"
    public static let agentAppFlavor = "agent_app_flavor"
    public static let agentAppTheme = "agent_app_theme"
    public static let agentAppVersion = "agent_app_version"
    public static let agentAppVersionName = "agent_app_version_name"
    public static let agentDeviceFamily = "agent_device_family"
    public static let agentDeviceLanguage = "agent_device_language"
    public static let agentReleaseStatus = "agent_release_status"

    public static let mediawikiDatabase = "mediawiki_database"

    public static let performerId = "performer_id"
    public static let performerName = "performer_name"
    public static let performerIsLoggedIn = "performer_is_logged_in"
    public static let performerIsTemp = "performer_is_temp"
    public static let performerSessionId = "performer_session_id"
    public static let performerPageviewId = "performer_pageview_id"
    public static let performerGroups = "performer_groups"
    public static let performerLanguageGroups = "performer_language_groups"
    public static let performerLanguagePrimary = "performer_language_primary"
    public static let performerRegistrationDt = "performer_registration_dt"

    static let requiredProperties: [String] = [
        agentAppFlavor,
        agentAppInstallId,
        agentAppTheme,
        agentAppVersion,
        agentAppVersionName,
        agentClientPlatform,
        agentClientPlatformFamily,
        agentDeviceFamily,
        agentDeviceLanguage,
        agentReleaseStatus
    ]
}
