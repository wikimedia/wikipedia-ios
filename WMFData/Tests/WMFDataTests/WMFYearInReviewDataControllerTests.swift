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
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: false, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPoint, "FR should not show entry point for mock config of with disabled YiR feature.")
    }
    
    func testYearInReviewEntryPointCountryCode() {
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
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
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
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
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPoint, "Should not show entry point when both personalized slides are disabled.")
    }
    
    func testYearInReviewEntryPointOneEnabledPersonalizedSlide() {
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = WMFYearInReviewDataController(developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertTrue(shouldShowEntryPoint, "Should show entry point when one personalized slide is enabled.")
    }
}
