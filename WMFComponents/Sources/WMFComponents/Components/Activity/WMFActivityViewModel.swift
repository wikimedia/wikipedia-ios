import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityViewModel: NSObject, ObservableObject {

    @Published var editActivityItem: ActivityItem?
    @Published var readActivityItem: ActivityItem?
    @Published var savedActivityItem: ActivityItem?
    
    @Published public var isLoggedIn: Bool
    @Published public var project: WMFProject?
    @Published public var username: String?
    
    let openHistory: () -> Void
    let openHistoryLoggedOut: () -> Void
    @Published public var loginAction: (() -> Void)?
    let openSavedArticles: () -> Void
    let openSuggestedEdits: (() -> Void)?
    let openStartEditing: (() -> Void)?
    let openEditingHistory: (() -> Void)?
    public var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    public var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
    let localizedStrings: LocalizedStrings
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var shouldShowAddAnImage: Bool {
        guard let editActivityItem else { return false }
        
        switch editActivityItem.type {
        case .noEdit:
            return getGroupAssigment() == .suggestedEdit
        default:
            return false
        }
    }
    
    public init(
            localizedStrings: LocalizedStrings,
            activityItems: [ActivityItem]? = nil,
            openHistory: @escaping () -> Void,
            openHistoryLoggedOut: @escaping () -> Void,
            openSavedArticles: @escaping () -> Void,
            openSuggestedEdits: (() -> Void)?,
            openStartEditing: (() -> Void)?,
            openEditingHistory: (() -> Void)?,
            loginAction: (() -> Void)?,
            isLoggedIn: Bool) {
        self.openHistory = openHistory
        self.openHistoryLoggedOut = openHistoryLoggedOut
        self.loginAction = loginAction
        self.openSavedArticles = openSavedArticles
        self.localizedStrings = localizedStrings
        self.isLoggedIn = isLoggedIn
        self.openSuggestedEdits = openSuggestedEdits
        self.openStartEditing = openStartEditing
        self.openEditingHistory = openEditingHistory
    }
    
    func title(for type: ActivityTabDisplayType) -> String {
        switch type {
        case .edit(let count):
            return localizedStrings.getActivityTabsEditTitle(count)
        case .read(let count):
            return localizedStrings.getActivityTabReadTitle(count)
        case .save(let count):
            return localizedStrings.getActivityTabSaveTitle(count)
        case .noEdit:
            if shouldShowAddAnImage {
                return localizedStrings.activityTabNoEditsAddImagesTitle
            } else {
                return localizedStrings.activityTabNoEditsGenericTitle
            }
        }
    }
    
    func action(for type: ActivityTabDisplayType) -> (() -> Void)? {
        switch type {
        case .edit:
            return openEditingHistory
        case .read:
            return openHistory
        case .save:
            return openSavedArticles
        case .noEdit:
            if shouldShowAddAnImage {
                return openSuggestedEdits
            } else {
                return openStartEditing
            }
        }
    }
    
    func backgroundColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit:
            theme.softEditorBlue
        case .save:
            theme.softEditorGreen
        case .read:
            theme.softEditorOrange
        }
    }
    
    func leadingIconColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit:
            theme.editorBlue
        case .save:
            theme.editorGreen
        case .read:
            theme.editorOrange
        }
    }
    
    func trailingIconName(for type: ActivityTabDisplayType) -> String {
        
        switch type {
        case .noEdit:
            if shouldShowAddAnImage {
                return "add-images"
            }
            return "activity-link"
        default:
            return "chevron.forward"
        }
    }
    
    func titleFont(for type: ActivityTabDisplayType) -> UIFont {
        switch type {
        case .noEdit:
            return WMFFont.for(.headline)
        default:
            return WMFFont.for(.boldHeadline)
        }
    }

    func getGroupAssigment() -> WMFActivityTabExperimentsDataController.ActivityTabExperimentAssignment {
        guard let dataController = WMFActivityTabExperimentsDataController.shared else {
            return .control
        }
        var assignment: WMFActivityTabExperimentsDataController.ActivityTabExperimentAssignment = .control

        do {
            let currentAssigment = try dataController.getActivityTabExperimentAssignment()
            assignment = currentAssigment
        } catch {
            debugPrint("Error fetching activity tab experiment: \(error)")
        }

        return assignment
    }


    public struct LocalizedStrings {
        let activityTabNoEditsAddImagesTitle: String
        let activityTabNoEditsGenericTitle: String
        let getActivityTabSaveTitle: (Int) -> String
        let getActivityTabReadTitle: (Int) -> String
        let getActivityTabsEditTitle: (Int) -> String
        let tabTitle: String
        let getGreeting: () -> String
        let viewHistory: String
        let viewSaved: String
        let viewEdited: String
        let logIn: String
        let loggedOutTitle: String
        let loggedOutSubtitle: String

        public init(activityTabNoEditsAddImagesTitle: String, activityTabNoEditsGenericTitle: String, getActivityTabSaveTitle: @escaping (Int) -> String, getActivityTabReadTitle: @escaping (Int) -> String, getActivityTabsEditTitle: @escaping (Int) -> String, tabTitle: String, getGreeting: @escaping () -> String, viewHistory: String, viewSaved: String, viewEdited: String, logIn: String, loggedOutTitle: String, loggedOutSubtitle: String) {
            self.activityTabNoEditsAddImagesTitle = activityTabNoEditsAddImagesTitle
            self.activityTabNoEditsGenericTitle = activityTabNoEditsGenericTitle
            self.getActivityTabSaveTitle = getActivityTabSaveTitle
            self.getActivityTabReadTitle = getActivityTabReadTitle
            self.getActivityTabsEditTitle = getActivityTabsEditTitle
            self.tabTitle = tabTitle
            self.getGreeting = getGreeting
            self.viewHistory = viewHistory
            self.viewSaved = viewSaved
            self.viewEdited = viewEdited
            self.logIn = logIn
            self.loggedOutTitle = loggedOutTitle
            self.loggedOutSubtitle = loggedOutSubtitle
        }
    }
}

public struct ActivityItem {
    let type: ActivityTabDisplayType
    
    var imageName: String {
        switch type {
        case .edit, .noEdit:
            return "activity-edit"
        case .read:
            return "activity-read"
        case .save:
            return "activity-save"
        }
    }
}

public enum ActivityTabDisplayType: Equatable {
    case edit(Int)
    case read(Int)
    case save(Int)
    case noEdit
}
