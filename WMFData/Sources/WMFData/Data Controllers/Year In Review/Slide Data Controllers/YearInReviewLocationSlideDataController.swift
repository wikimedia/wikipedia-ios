import CoreData

final class YearInReviewLocationSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.location.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    private var legacyPageViews: [WMFLegacyPageView]

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
        self.legacyPageViews = []
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate,
            let pageViews = try await legacyPageViewsDataDelegate?.getLegacyPageViews(from: startDate, to: endDate, needsLatLong: true) else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        legacyPageViews = [
            WMFLegacyPageView(title: "Eiffel Tower", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)), viewedDate: Date(), latitude: 48.858222206788668, longitude: 2.2945000190042322),
            WMFLegacyPageView(title: "The Louvre", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)), viewedDate: Date(), latitude: 48.861111113536424, longitude: 2.3358333628475236)
        ]
        
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        let encoder = JSONEncoder()
        slide.data = try encoder.encode(legacyPageViews)

        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.locationsIsEnabled
    }
}
