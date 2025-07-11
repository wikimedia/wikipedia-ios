import Foundation
import CoreData

public final class YearInReviewSlideDataControllerFactory {
    
    private let year: Int
    private let config: YearInReviewFeatureConfig
    
    private let fetchLegacyPageViews: () async throws -> [WMFLegacyPageView]
    private let fetchSavedArticlesData: () async -> SavedArticleSlideData?
    
    private let fetchEditCount: (String, WMFProject?) async throws -> Int
    private let fetchEditViews: (WMFProject?, String, String) async throws -> Int
    private let donationFetcher: (Date, Date) -> Int?
    
    private let username: String?
    private let userID: String?
    private let project: WMFProject?
    
    public init(
        year: Int,
        config: YearInReviewFeatureConfig,
        username: String?,
        userID: String?,
        project: WMFProject?,
        fetchLegacyPageViews: @escaping () async throws -> [WMFLegacyPageView],
        fetchSavedArticlesData: @escaping () async -> SavedArticleSlideData?,
        fetchEditCount: @escaping (String, WMFProject?) async throws -> Int,
        fetchEditViews: @escaping (WMFProject?, String, String) async throws -> Int,
        donationFetcher: @escaping (Date, Date) -> Int?
    ) {
        self.year = year
        self.config = config
        self.username = username
        self.userID = userID
        self.project = project
        self.fetchLegacyPageViews = fetchLegacyPageViews
        self.fetchSavedArticlesData = fetchSavedArticlesData
        self.fetchEditCount = fetchEditCount
        self.fetchEditViews = fetchEditViews
        self.donationFetcher = donationFetcher
    }
    
    public func makeSlideDataControllers(missingFrom existingSlideIDs: Set<String>) async throws -> [YearInReviewSlideDataControllerProtocol] {
        var slides: [YearInReviewSlideDataControllerProtocol] = []
        
        let legacyPageViews = try await fetchLegacyPageViews()
        let savedArticlesData = await fetchSavedArticlesData()
        
        let userInfo = YearInReviewUserInfo(
            username: username,
            userID: userID,
            project: project,
            legacyPageViews: legacyPageViews,
            savedArticlesData: savedArticlesData
        )
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .readCount),
           YearInReviewReadCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewReadCountSlideDataController(year: year, legacyPageViews: legacyPageViews))
        }
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .editCount),
           YearInReviewEditCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewEditCountSlideDataController(
                year: year,
                username: username,
                project: project,
                fetchEditCount: fetchEditCount
            ))
        }
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .donateCount),
           YearInReviewDonateCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo),
           let start = config.dataPopulationStartDate,
           let end = config.dataPopulationEndDate {
            slides.append(YearInReviewDonateCountSlideDataController(
                year: year,
                dateRange: (start, end),
                donationFetcher: donationFetcher
            ))
        }
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .saveCount),
           YearInReviewSaveCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewSaveCountSlideDataController(
                year: year,
                savedData: savedArticlesData
            ))
        }
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .mostReadDay),
           YearInReviewMostReadDaySlideDataController.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewMostReadDaySlideDataController(
                year: year,
                legacyPageViews: legacyPageViews
            ))
        }
        
        if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: .viewCount),
           YearInReviewViewCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo),
           let userID, let lang = project?.languageCode {
            slides.append(YearInReviewViewCountSlideDataController(
                year: year,
                userID: userID,
                languageCode: lang,
                project: project,
                fetchViews: fetchEditViews
            ))
        }
        
        return slides
    }
    
    private func shouldAddSlideDataController(existingSlideIDs: Set<String>, id: WMFYearInReviewPersonalizedSlideID) -> Bool {
        !existingSlideIDs.contains(id.rawValue)
    }
}
