import Foundation
import CoreData

public final class YearInReviewSlideFactory {
    
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
    
    public func makeSlides(missingFrom existingSlideIDs: Set<String>) async throws -> [YearInReviewSlideProtocol] {
        var slides: [YearInReviewSlideProtocol] = []
        
        let legacyPageViews = try await fetchLegacyPageViews()
        let savedArticlesData = await fetchSavedArticlesData()
        
        let userInfo = YearInReviewUserInfo(
            username: username,
            userID: userID,
            project: project,
            legacyPageViews: legacyPageViews,
            savedArticlesData: savedArticlesData
        )
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .readCount),
           YearInReviewReadCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewReadCountSlide(year: year, legacyPageViews: legacyPageViews))
        }
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .editCount),
           YearInReviewEditCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewEditCountSlide(
                year: year,
                username: username,
                project: project,
                fetchEditCount: fetchEditCount
            ))
        }
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .donateCount),
           YearInReviewDonateCountSlide.shouldPopulate(from: config, userInfo: userInfo),
           let start = config.dataPopulationStartDate,
           let end = config.dataPopulationEndDate {
            slides.append(YearInReviewDonateCountSlide(
                year: year,
                dateRange: (start, end),
                donationFetcher: donationFetcher
            ))
        }
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .saveCount),
           YearInReviewSaveCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewSaveCountSlide(
                year: year,
                savedData: savedArticlesData
            ))
        }
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .mostReadDay),
           YearInReviewMostReadDaySlide.shouldPopulate(from: config, userInfo: userInfo) {
            slides.append(YearInReviewMostReadDaySlide(
                year: year,
                legacyPageViews: legacyPageViews
            ))
        }
        
        if shouldAddSlide(existingSlideIDs: existingSlideIDs, id: .viewCount),
           YearInReviewViewCountSlide.shouldPopulate(from: config, userInfo: userInfo),
           let userID, let lang = project?.languageCode {
            slides.append(YearInReviewViewCountSlide(
                year: year,
                userID: userID,
                languageCode: lang,
                project: project,
                fetchViews: fetchEditViews
            ))
        }
        
        return slides
    }
    
    private func shouldAddSlide(existingSlideIDs: Set<String>, id: WMFYearInReviewPersonalizedSlideID) -> Bool {
        !existingSlideIDs.contains(id.rawValue)
    }
}
