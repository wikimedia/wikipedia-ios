import Foundation

@objc public final class WKDeveloperSettingsDataController: NSObject {

    @objc public static let shared = WKDeveloperSettingsDataController()

    private let userDefaultsStore = WKDataEnvironment.current.userDefaultsStore
    
    public var doNotPostImageRecommendationsEdit: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: newValue)
        }
    }

    @objc public var enableAltTextExperiment: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.developerSettingsEnableAltTextExperiment.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.developerSettingsEnableAltTextExperiment.rawValue, value: newValue)
        }
    }
    
    @objc public var enableAltTextExperimentForEN: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue, value: newValue)
        }
    }
    
    @objc public var sendAnalyticsToWMFLabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue, value: newValue)
        }
    }
}
