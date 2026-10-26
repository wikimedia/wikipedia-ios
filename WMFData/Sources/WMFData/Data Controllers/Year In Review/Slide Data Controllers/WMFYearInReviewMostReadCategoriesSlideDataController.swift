import CoreData

// @unchecked: `isEvaluated` and `selectedCategoryName` are mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewMostReadCategoriesSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadCategories.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    /// The user must read at least this number of articles in a category for it to be a candidate.
    static let minimumArticleCount = 2

    /// A category name must have at least this number of spaces to be a first-choice candidate.
    /// Names with more words are more specific, so they show a niche interest.
    static let minimumSpaceCount = 2

    /// The category that the slide shows. It is nil when no category is a candidate.
    private var selectedCategoryName: String?

    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {

        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            return
        }

        let categoryCounts = try await WMFCategoriesDataController().fetchCategoryCounts(startDate: startDate, endDate: endDate)

        let counts = categoryCounts.map { item in
            (name: item.key.categoryName.replacingOccurrences(of: "_", with: " "), count: item.value)
        }

        var generator = SystemRandomNumberGenerator()
        selectedCategoryName = Self.selectCategoryName(from: counts, using: &generator)

        isEvaluated = true
    }

    /// Picks one category at random.
    ///
    /// 1. Keep the categories with `minimumArticleCount` or more articles.
    /// 2. From those, keep the names with `minimumSpaceCount` or more spaces.
    /// 3. If step 2 leaves no category, use the result of step 1 instead.
    ///
    /// The names are sorted before the pick, so a seeded generator gives the same result each time.
    /// Returns nil when step 1 leaves no category.
    static func selectCategoryName<Generator: RandomNumberGenerator>(from counts: [(name: String, count: Int)], using generator: inout Generator) -> String? {
        let candidates = counts.filter { $0.count >= minimumArticleCount }
        let specificCandidates = candidates.filter { candidate in
            candidate.name.filter { $0 == " " }.count >= minimumSpaceCount
        }
        let pool = specificCandidates.isEmpty ? candidates : specificCandidates
        return pool.map(\.name).sorted().randomElement(using: &generator)
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try JSONEncoder().encode(WMFYearInReviewMostReadCategorySlideData(categoryName: selectedCategoryName))
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
