import Foundation

@objc public final class WMFDeveloperSettingsDataController: NSObject {

    @objc public static let shared = WMFDeveloperSettingsDataController()

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
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
}
