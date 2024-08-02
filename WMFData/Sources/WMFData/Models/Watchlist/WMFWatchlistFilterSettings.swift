import Foundation

public struct WMFWatchlistFilterSettings: Codable, Equatable {

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
    
    public let offProjects: [WMFProject]
    public let latestRevisions: LatestRevisions
    public let activity: Activity
    public let automatedContributions: AutomatedContributions
    public let significance: Significance
    public let userRegistration: UserRegistration
    public let offTypes: [ChangeType]
    
    public init(offProjects: [WMFProject], latestRevisions: WMFWatchlistFilterSettings.LatestRevisions, activity: WMFWatchlistFilterSettings.Activity, automatedContributions: WMFWatchlistFilterSettings.AutomatedContributions, significance: WMFWatchlistFilterSettings.Significance, userRegistration: WMFWatchlistFilterSettings.UserRegistration, offTypes: [WMFWatchlistFilterSettings.ChangeType]) {
        
        self.offProjects = offProjects
        self.latestRevisions = latestRevisions
        self.activity = activity
        self.automatedContributions = automatedContributions
        self.significance = significance
        self.userRegistration = userRegistration
        self.offTypes = offTypes
    }
    
    init(latestRevisions: WMFWatchlistFilterSettings.LatestRevisions = .notTheLatestRevision, activity: WMFWatchlistFilterSettings.Activity = .all, automatedContributions: WMFWatchlistFilterSettings.AutomatedContributions = .all, significance: WMFWatchlistFilterSettings.Significance = .all, userRegistration: WMFWatchlistFilterSettings.UserRegistration = .all, offTypes: [WMFWatchlistFilterSettings.ChangeType] = []) {

        self.offProjects = []
        self.latestRevisions = latestRevisions
        self.activity = activity
        self.automatedContributions = automatedContributions
        self.significance = significance
        self.userRegistration = userRegistration
        self.offTypes = []
    }
}
