import Foundation
import CoreData

final class YearInReviewSlideDataControllerFactory {
    
    private let year: Int
    private let config: WMFFeatureConfigResponse.Common.YearInReview
    
    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private weak var mainPageIdentifier: WMFMainPageIdentifying?
    
    private let username: String?
    private let userID: Int?
    private let globalUserID: Int?
    private let project: WMFProject?
    
    init(
        year: Int,
        config: WMFFeatureConfigResponse.Common.YearInReview,
        username: String?,
        userID: Int?,
        globalUserID: Int?,
        project: WMFProject?,
        savedSlideDataDelegate: SavedArticleSlideDataDelegate,
        legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate,
        mainPageIdentifier: WMFMainPageIdentifying? = nil
    ) {
        self.year = year
        self.config = config
        self.username = username
        self.userID = userID
        self.globalUserID = globalUserID
        self.project = project
        
        self.savedSlideDataDelegate = savedSlideDataDelegate
        self.legacyPageViewsDataDelegate = legacyPageViewsDataDelegate
        self.mainPageIdentifier = mainPageIdentifier
    }
    
    func makeSlideDataControllers(missingFrom existingSlideIDs: Set<String>) async throws -> [YearInReviewSlideDataControllerProtocol] {
        
        let userInfo = YearInReviewUserInfo(
            username: username,
            userID: userID,
            globalUserID: globalUserID,
            project: project
        )
        
        let possibleSlideIDs: [WMFYearInReviewPersonalizedSlideID] = [
            .readCount,
            .editCount,
            .donateCount,
            .saveCount,
            .mostReadDate,
            .viewCount,
            .mostReadCategories,
            .location,
            .topArticles,
            .topTopics,
            .daysVisited,
            .mostViewedArticles,
            .rabbitHoles,
            .readingStreak,
            .readingPattern,
            .biggestReadingDay,
            .longestRead
        ]
        
        let dataControllerTypes = possibleSlideIDs
            .filter { shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: $0) }
            .map { $0.dataController() }
            .filter { $0.shouldPopulate(from: config, userInfo: userInfo) }

        // Look up the main pages once for all the slides, and only when a slide reads the reading history.
        var mainPageTitles: YearInReviewMainPageTitles? = .englishOnly
        if dataControllerTypes.contains(where: { $0.personalizationSources.contains(.readingHistory) }),
           let startDate = config.dataStartDate,
           let endDate = config.dataEndDate {
            do {
                mainPageTitles = try await YearInReviewMainPageTitles.lookUp(startDate: startDate, endDate: endDate, pageViewsDataController: try WMFPageViewsDataController(), mainPageIdentifier: mainPageIdentifier)
            } catch {
                // Without the main pages, the slides that leave them out would count them. Those
                // slides fail this run, like a slide whose own fetch fails, so the next run builds them.
                mainPageTitles = nil
            }
        }

        let dependencies = YearInReviewSlideDataControllerDependencies.init(legacyPageViewsDataDelegate: legacyPageViewsDataDelegate, savedSlideDataDelegate: savedSlideDataDelegate, username: username, project: project, userID: userID, globalUserID: globalUserID, languageCode: project?.languageCode, userImpactDataProvider: WMFUserImpactDataController.shared, mainPageTitles: mainPageTitles)

        let dataControllers: [YearInReviewSlideDataControllerProtocol] = dataControllerTypes.map {
            $0.init(year: year, yirConfig: config, dependencies: dependencies)
        }
        
        return dataControllers
    }
    
    private func shouldAddSlideDataController(existingSlideIDs: Set<String>, id: WMFYearInReviewPersonalizedSlideID) -> Bool {
        
        // If slide should not freeze its data, always return true, which will trigger calculation each time.
        if !id.dataController().shouldFreeze {
            return true
        }
        
        return !existingSlideIDs.contains(id.rawValue)
    }
}
