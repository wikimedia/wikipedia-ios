import Foundation

public struct WKWatchlistFilterSettings: Codable, Equatable {

    public enum LatestRevisions: Int, Codable {
        case latestRevision
        case notTheLatestRevision
    }
    
    public enum Activity: Int, Codable {
        case all
        case unseenChanges
        case seenChanges
    }
    
    public enum AutomatedContributions: Int, Codable {
        case all
        case bot
        case human
    }
    
    public enum Significance: Int, Codable {
        case all
        case minorEdits
        case nonMinorEdits
    }
    
    public enum UserRegistration: Int, Codable {
        case all
        case unregistered
        case registered
    }
    
    public enum ChangeType: Int, Codable, CaseIterable {
        case pageEdits
        case pageCreations
        case categoryChanges
        case wikidataEdits
        case loggedActions
    }
    
    public let offProjects: [WKProject]
    public let latestRevisions: LatestRevisions
    public let activity: Activity
    public let automatedContributions: AutomatedContributions
    public let significance: Significance
    public let userRegistration: UserRegistration
    public let offTypes: [ChangeType]
    
    public init(offProjects: [WKProject], latestRevisions: WKWatchlistFilterSettings.LatestRevisions, activity: WKWatchlistFilterSettings.Activity, automatedContributions: WKWatchlistFilterSettings.AutomatedContributions, significance: WKWatchlistFilterSettings.Significance, userRegistration: WKWatchlistFilterSettings.UserRegistration, offTypes: [WKWatchlistFilterSettings.ChangeType]) {
        
        self.offProjects = offProjects
        self.latestRevisions = latestRevisions
        self.activity = activity
        self.automatedContributions = automatedContributions
        self.significance = significance
        self.userRegistration = userRegistration
        self.offTypes = offTypes
    }
    
    init(latestRevisions: WKWatchlistFilterSettings.LatestRevisions = .notTheLatestRevision, activity: WKWatchlistFilterSettings.Activity = .all, automatedContributions: WKWatchlistFilterSettings.AutomatedContributions = .all, significance: WKWatchlistFilterSettings.Significance = .all, userRegistration: WKWatchlistFilterSettings.UserRegistration = .all, offTypes: [WKWatchlistFilterSettings.ChangeType] = []) {

        self.offProjects = []
        self.latestRevisions = latestRevisions
        self.activity = activity
        self.automatedContributions = automatedContributions
        self.significance = significance
        self.userRegistration = userRegistration
        self.offTypes = []
    }
}
