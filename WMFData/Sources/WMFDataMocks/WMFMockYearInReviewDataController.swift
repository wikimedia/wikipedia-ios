@testable import WMFData
import CoreData

#if DEBUG

class WMFMockYearInReviewDataController: WMFYearInReviewDataController {
    var shouldCreateOrRetrieve = true
    var mockSlides: [WMFYearInReviewSlide] = []
    
    override init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, developerSettingsDataController: any WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {
        
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: false, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        try super.init(coreDataStore: coreDataStore, developerSettingsDataController: developerSettingsDataController)
    }

    override func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        return shouldCreateOrRetrieve
    }

    override func initialSlides(year: Int, moc: NSManagedObjectContext) throws -> Set<CDYearInReviewSlide> {
        
        var results = Set<CDYearInReviewSlide>()

        let editCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        editCountSlide.year = 2023
        editCountSlide.id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
        editCountSlide.evaluated = false
        editCountSlide.display = false
        editCountSlide.data = nil
        results.insert(editCountSlide)
        return results
    }
}

#endif
