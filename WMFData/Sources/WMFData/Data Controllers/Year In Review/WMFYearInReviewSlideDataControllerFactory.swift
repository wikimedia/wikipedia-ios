import Foundation
import CoreData

final class YearInReviewSlideDataControllerFactory {
    
    private let year: Int
    private let config: YearInReviewFeatureConfig
    
    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
    private let username: String?
    private let userID: String?
    private let project: WMFProject?
    
    init(
        year: Int,
        config: YearInReviewFeatureConfig,
        username: String?,
        userID: String?,
        project: WMFProject?,
        savedSlideDataDelegate: SavedArticleSlideDataDelegate,
        legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate
    ) {
        self.year = year
        self.config = config
        self.username = username
        self.userID = userID
        self.project = project
        
        self.savedSlideDataDelegate = savedSlideDataDelegate
        self.legacyPageViewsDataDelegate = legacyPageViewsDataDelegate
    }
    
    func makeSlideDataControllers(missingFrom existingSlideIDs: Set<String>) async throws -> [YearInReviewSlideDataControllerProtocol] {
        
        let userInfo = YearInReviewUserInfo(
            username: username,
            userID: userID,
            project: project
        )
        
        let possibleSlideIDs: [WMFYearInReviewPersonalizedSlideID] = [
            .readCount,
            .editCount,
            .donateCount,
            .saveCount,
            .mostReadDay,
            .viewCount
        ]
        
        let dependencies = YearInReviewSlideDataControllerDependencies.init(legacyPageViewsDataDelegate: legacyPageViewsDataDelegate, savedSlideDataDelegate: savedSlideDataDelegate, username: username, project: project, userID: userID, languageCode: project?.languageCode)
        
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
        !existingSlideIDs.contains(id.rawValue)
    }
}
