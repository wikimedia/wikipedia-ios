import Foundation
import CoreData

public final class YearInReviewSlideFactory {

    private let year: Int
    private let config: YearInReviewFeatureConfig
    private let userInfo: YearInReviewUserInfo

    private let fetchEditCount: (String, WMFProject?) async throws -> Int
    private let fetchEditViews: (WMFProject?, String, String) async throws -> Int
    private let donationFetcher: (Date, Date) -> Int?

    public init(
        year: Int,
        config: YearInReviewFeatureConfig,
        userInfo: YearInReviewUserInfo,
        fetchEditCount: @escaping (String, WMFProject?) async throws -> Int,
        fetchEditViews: @escaping (WMFProject?, String, String) async throws -> Int,
        donationFetcher: @escaping (Date, Date) -> Int?
    ) {
        self.year = year
        self.config = config
        self.userInfo = userInfo
        self.fetchEditCount = fetchEditCount
        self.fetchEditViews = fetchEditViews
        self.donationFetcher = donationFetcher
    }

    public func makeSlides() -> [YearInReviewSlideProtocol] {
        var slides: [YearInReviewSlideProtocol] = []

        if YearInReviewReadCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            let slide = YearInReviewReadCountSlide(year: year, legacyPageViews: userInfo.legacyPageViews)
            slides.append(slide)
        }

        if YearInReviewEditCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            let slide = YearInReviewEditCountSlide(
                year: year,
                username: userInfo.username,
                project: userInfo.project,
                fetchEditCount: fetchEditCount
            )
            slides.append(slide)
        }

        if YearInReviewDonateCountSlide.shouldPopulate(from: config, userInfo: userInfo),
           let start = config.dataPopulationStartDate,
           let end = config.dataPopulationEndDate {
            let slide = YearInReviewDonateCountSlide(
                year: year,
                dateRange: (start, end),
                donationFetcher: donationFetcher
            )
            slides.append(slide)
        }

        if YearInReviewSaveCountSlide.shouldPopulate(from: config, userInfo: userInfo) {
            let slide = YearInReviewSaveCountSlide(
                year: year,
                savedData: userInfo.savedArticlesData
            )
            slides.append(slide)
        }

        if YearInReviewMostReadDaySlide.shouldPopulate(from: config, userInfo: userInfo) {
            let slide = YearInReviewMostReadDaySlide(
                year: year,
                legacyPageViews: userInfo.legacyPageViews
            )
            slides.append(slide)
        }

        if YearInReviewViewCountSlide.shouldPopulate(from: config, userInfo: userInfo),
           let userID = userInfo.userID,
           let lang = userInfo.project?.languageCode {
            let slide = YearInReviewViewCountSlide(
                year: year,
                userID: userID,
                languageCode: lang,
                project: userInfo.project,
                fetchViews: fetchEditViews
            )
            slides.append(slide)
        }

        return slides
    }
}
