import Foundation
import CoreData

final class YearInReviewSlideDataControllerFactory {
    
    private let year: Int
    private let config: WMFFeatureConfigResponse.Common.YearInReview
    
    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
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
        legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate
    ) {
        self.year = year
        self.config = config
        self.username = username
        self.userID = userID
        self.globalUserID = globalUserID
        self.project = project
        
        self.savedSlideDataDelegate = savedSlideDataDelegate
        self.legacyPageViewsDataDelegate = legacyPageViewsDataDelegate
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
            .topArticles
        ]
        
        let dependencies = YearInReviewSlideDataControllerDependencies.init(legacyPageViewsDataDelegate: legacyPageViewsDataDelegate, savedSlideDataDelegate: savedSlideDataDelegate, username: username, project: project, userID: userID, globalUserID: globalUserID, languageCode: project?.languageCode)
        
        var dataControllers: [YearInReviewSlideDataControllerProtocol] = []
        
        for possibleSlideId in possibleSlideIDs {
            if shouldAddSlideDataController(existingSlideIDs: existingSlideIDs, id: possibleSlideId) {
                let dataControllerType = possibleSlideId.dataController()
                if dataControllerType.shouldPopulate(from: config, userInfo: userInfo) {
                    dataControllers.append(dataControllerType.init(year: year, yirConfig: config, dependencies: dependencies))
                }
            }
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
