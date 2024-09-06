import Foundation

@objc public final class WMFDeveloperSettingsDataController: NSObject {

    @objc public static let shared = WMFDeveloperSettingsDataController()

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    public var doNotPostImageRecommendationsEdit: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: newValue)
        }
    }
    
    @objc public var enableAltTextExperimentForEN: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue, value: newValue)
        }
    }
    
    @objc public var alwaysShowAltTextEntryPoint: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.alwaysShowAltTextEntryPoint.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.alwaysShowAltTextEntryPoint.rawValue, value: newValue)
        }
    }
    
    @objc public var sendAnalyticsToWMFLabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue, value: newValue)
        }
    }
}
