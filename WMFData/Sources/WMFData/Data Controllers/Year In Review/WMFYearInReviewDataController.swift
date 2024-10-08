enum WMFYearInReviewPersonalizedSlideID: String {
    case readCount
    case editCount
}

public final class WMFYearInReviewDataController {
    
    let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    
    init(developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) {
        self.developerSettingsDataController = developerSettingsDataController
    }
    
    public func shouldShowYearInReviewEntryPoint(countryCode: String, primaryAppLanguageProject: WMFProject) -> Bool {
        
        // TODO: Check developer settings local feature flag. https://phabricator.wikimedia.org/T376041
        
        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first else {
            return false
        }
        
        // Check remote feature disable switch
        guard iosFeatureConfig.yir.isEnabled else {
            return false
        }
        
        
        // Check remote valid country codes
        let uppercaseConfigCountryCodes = iosFeatureConfig.yir.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }
        
        // Check remote valid primary app language wikis
        let uppercaseConfigPrimaryAppLanguageCodes = iosFeatureConfig.yir.primaryAppLanguageCodes.map { $0.uppercased() }
        guard let languageCode = primaryAppLanguageProject.languageCode,
              uppercaseConfigPrimaryAppLanguageCodes.contains(languageCode.uppercased()) else {
            return false
        }
        
        var personalizedSlideCount = 0
        
        // TODO: Check persisted slide item here https://phabricator.wikimedia.org/T376041
        // if {read_count persisted slide item}.display == yes {
            if iosFeatureConfig.yir.personalizedSlides.readCount.isEnabled {
                personalizedSlideCount += 1
            }
        // }
        
        // TODO: Check persisted slide item here https://phabricator.wikimedia.org/T376041
        // if {edit_count persisted slide item}.display == yes {
            if iosFeatureConfig.yir.personalizedSlides.editCount.isEnabled {
                personalizedSlideCount += 1
            }
        // }
        
        guard personalizedSlideCount >= 1 else {
            return false
        }
        
        return true
    }
}
