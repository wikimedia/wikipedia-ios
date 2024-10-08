import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFYearInReviewDataControllerTests: XCTestCase {
    
    private var enProject: WMFProject {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return WMFProject.wikipedia(language)
    }
    
    private var usCountryCode: String? {
        return Locale(identifier: "en_US").region?.identifier
    }
    
    private var frCountryCode: String? {
        return Locale(identifier: "fr_FR").region?.identifier
    }
    
    private var frProject: WMFProject {
        let language = WMFLanguage(languageCode: "fr", languageVariantCode: nil)
        return WMFProject.wikipedia(language)
    }
    
    func testYearInReviewEntryPointFeatureDisabled() {
        let ios = WMFFeatureConfigResponse.FeatureConfigIOS(version: 1, yirIsEnabled: false, yirCountryCodes: ["FR", "IT"], yirPrimaryAppLanguageCodes: ["fr", "it"], yirDataPopulationStartDateString: "2024-01-01T00:00:00Z", yirDataPopulationEndDateString: "2024-11-01T00:00:00Z", yirDataPopulationFetchMaxPagesPerSession: 3, yirPersonalizedSlides: [
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "read_count", isEnabled: true),
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "edit_count", isEnabled: true)
        ])
        
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPointFR = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPointFR, "FR should not show entry point for mock config of with disabled YiR feature.")
    }
    
    func testYearInReviewEntryPointCountryCode() {
        
        let ios = WMFFeatureConfigResponse.FeatureConfigIOS(version: 1, yirIsEnabled: true, yirCountryCodes: ["FR", "IT"], yirPrimaryAppLanguageCodes: ["fr", "it"], yirDataPopulationStartDateString: "2024-01-01T00:00:00Z", yirDataPopulationEndDateString: "2024-11-01T00:00:00Z", yirDataPopulationFetchMaxPagesPerSession: 3, yirPersonalizedSlides: [
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "read_count", isEnabled: true),
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "edit_count", isEnabled: true)
        ])
        
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let usCountryCode, let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPointUS = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: usCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPointUS, "US should not show entry point for mock YiR config of [FR, IT] country codes.")

        let shouldShowEntryPointFR = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertTrue(shouldShowEntryPointFR, "FR should show entry point for mock YiR config of [FR, IT] country codes.")
    }
    
    func testYearInReviewEntryPointPrimaryAppLanguageProject() {
        
        let ios = WMFFeatureConfigResponse.FeatureConfigIOS(version: 1, yirIsEnabled: true, yirCountryCodes: ["FR", "IT"], yirPrimaryAppLanguageCodes: ["fr", "it"], yirDataPopulationStartDateString: "2024-01-01T00:00:00Z", yirDataPopulationEndDateString: "2024-11-01T00:00:00Z", yirDataPopulationFetchMaxPagesPerSession: 3, yirPersonalizedSlides: [
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "read_count", isEnabled: true),
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "edit_count", isEnabled: true)
        ])
        
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPointENProject = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: enProject)
        
        XCTAssertFalse(shouldShowEntryPointENProject, "Primary app language EN project should not show entry point for mock YiR config of [FR, IT] primary app language projects.")

        let shouldShowEntryPointFRProject = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertTrue(shouldShowEntryPointFRProject, "Primary app language FR project should show entry point for mock YiR config of [FR, IT] primary app language projects.")
    }
    
    func testYearInReviewEntryPointDisabledPersonalizedSlides() {
        
        let ios = WMFFeatureConfigResponse.FeatureConfigIOS(version: 1, yirIsEnabled: true, yirCountryCodes: ["FR", "IT"], yirPrimaryAppLanguageCodes: ["fr", "it"], yirDataPopulationStartDateString: "2024-01-01T00:00:00Z", yirDataPopulationEndDateString: "2024-11-01T00:00:00Z", yirDataPopulationFetchMaxPagesPerSession: 3, yirPersonalizedSlides: [
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "read_count", isEnabled: false),
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "edit_count", isEnabled: false)
        ])
        
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPointDisabledSlides = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPointDisabledSlides, "Should not show entry point when both personalized slides are disabled.")
    }
    
    func testYearInReviewEntryPointOneEnabledPersonalizedSlide() {
        
        let ios = WMFFeatureConfigResponse.FeatureConfigIOS(version: 1, yirIsEnabled: true, yirCountryCodes: ["FR", "IT"], yirPrimaryAppLanguageCodes: ["fr", "it"], yirDataPopulationStartDateString: "2024-01-01T00:00:00Z", yirDataPopulationEndDateString: "2024-11-01T00:00:00Z", yirDataPopulationFetchMaxPagesPerSession: 3, yirPersonalizedSlides: [
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "read_count", isEnabled: true),
            WMFFeatureConfigResponse.FeatureConfigIOS.Slide(id: "edit_count", isEnabled: false)
        ])
        
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPointOneEnabledSlide = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertTrue(shouldShowEntryPointOneEnabledSlide, "Should show entry point when one personalized slide is enabled.")
    }
}
