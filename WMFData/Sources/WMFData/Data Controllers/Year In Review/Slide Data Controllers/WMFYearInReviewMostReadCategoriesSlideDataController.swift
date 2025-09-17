import CoreData

final class YearInReviewMostReadCategoriesSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadCategories.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false

    private var mostReadCategories: [String]

    private let yirConfig: YearInReviewFeatureConfig

    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        mostReadCategories = []
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {

        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate else {
            return
        }

        let categoryCounts = try await WMFCategoriesDataController().fetchCategoryCounts(startDate: startDate, endDate: endDate)

        let filteredTop5 = Array(categoryCounts
            .filter { key, _ in
                key.categoryName.components(separatedBy: "_").count - 1 >= 2
            }
            .sorted { $0.value > $1.value }
            .prefix(5)).map { item in
                return item.key.categoryName.replacingOccurrences(of: "_", with: " ")
            }
        mostReadCategories = ["Executed female serial killers", "Shapeshifters in Greek mythology", "Mass media-related controversies in the United States"]

        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try JSONEncoder().encode(mostReadCategories)
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.categoriesIsEnabled
    }
}
