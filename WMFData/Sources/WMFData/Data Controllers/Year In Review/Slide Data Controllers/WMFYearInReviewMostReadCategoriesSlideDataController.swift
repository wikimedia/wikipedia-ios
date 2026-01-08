import CoreData

final class YearInReviewMostReadCategoriesSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadCategories.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    static var shouldFreeze = true

    private var mostReadCategories: [String]

    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        mostReadCategories = []
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {

        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            return
        }

        let categoryCounts = try await WMFCategoriesDataController().fetchCategoryCounts(startDate: startDate, endDate: endDate)

        var filtered = categoryCounts
            .filter { key, _ in
                key.categoryName.components(separatedBy: "_").count - 1 >= 2
            }
            .sorted { $0.value > $1.value }
            .prefix(5)

        if filtered.isEmpty {
            filtered = categoryCounts
                .sorted { $0.value > $1.value }
                .prefix(5)
        }

        let filteredTop5 = filtered.map { item in
            item.key.categoryName.replacingOccurrences(of: "_", with: " ")
        }

        mostReadCategories = filteredTop5

        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try JSONEncoder().encode(mostReadCategories)
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
