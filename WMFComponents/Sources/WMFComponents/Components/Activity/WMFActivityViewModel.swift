import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityViewModel: NSObject, ObservableObject {

    @Published var editActivityItem: ActivityItem?
    @Published var readActivityItem: ActivityItem?
    @Published var savedActivityItem: ActivityItem?
    
    @Published public var isLoggedIn: Bool
    @Published public var project: WMFProject?
    var shouldShowAddAnImage: Bool
    var shouldShowStartEditing: Bool
    let openHistory: () -> Void
    @Published public var loginAction: (() -> Void)?
    let openSavedArticles: () -> Void
    let openSuggestedEdits: (() -> Void)?
    let openStartEditing: (() -> Void)?
    let openAddAnImage: (() -> Void)?
    public var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    public var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
    // TODO: Localize strings
    
    // Add an image strings
    let addAnImageButtonTitle = "Add"
    let addAnImageTitle = "Add images"
    let addAnImageSubtitle = "Add suggested images to Wikipedia articles to enhance understanding."
    
    let suggestedEdits = "Suggested edits"
    
    var localizedStrings: LocalizedStrings
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(
            localizedStrings: LocalizedStrings,
            activityItems: [ActivityItem]? = nil,
            shouldShowAddAnImage: Bool,
            shouldShowStartEditing: Bool,
            hasNoEdits: Bool,
            openHistory: @escaping () -> Void,
            openSavedArticles: @escaping () -> Void,
            openSuggestedEdits: (() -> Void)?,
            openStartEditing: (() -> Void)?,
            openAddAnImage: (() -> Void)?,
            loginAction: (() -> Void)?,
            isLoggedIn: Bool) {
        self.shouldShowAddAnImage = shouldShowAddAnImage
        self.shouldShowStartEditing = shouldShowStartEditing
        self.openHistory = openHistory
        self.loginAction = loginAction
        self.openSavedArticles = openSavedArticles
        self.openAddAnImage = openAddAnImage
        self.localizedStrings = localizedStrings
        self.isLoggedIn = isLoggedIn
        self.openSuggestedEdits = openSuggestedEdits
        self.openStartEditing = openStartEditing
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
            return localizedStrings.activityTabNoEditsTitle
        case .addImage:
            return "Add images to enhance article understanding."
        }
    }
    
    func action(for type: ActivityTabDisplayType) -> (() -> Void)? {
        switch type {
        case .edit, .addImage:
            return nil
        case .read:
            return openHistory
        case .save:
            return openSavedArticles
        case .noEdit:
            return openStartEditing
        }
    }
    
    func backgroundColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit, .addImage:
            theme.softEditorBlue
        case .save:
            theme.softEditorGreen
        case .read:
            theme.softEditorOrange
        }
    }
    
    func leadingIconColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit, .addImage:
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
            return "activity-link"
        case .addImage:
            return "add-images"
        default:
            return "chevron.forward"
        }
    }
    
    func borderColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit, .addImage:
            WMFColor.blue100
        case .save:
            WMFColor.green100
        case .read:
            WMFColor.beige100
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

    public struct LocalizedStrings {
        let activityTabNoEditsTitle: String
        let getActivityTabSaveTitle: (Int) -> String
        let getActivityTabReadTitle: (Int) -> String
        let getActivityTabsEditTitle: (Int) -> String
        let tabTitle: String
        let getGreeting: () -> String

        public init(activityTabNoEditsTitle: String, getActivityTabSaveTitle: @escaping (Int) -> String, getActivityTabReadTitle: @escaping (Int) -> String, getActivityTabsEditTitle: @escaping (Int) -> String, tabTitle: String, getGreeting: @escaping () -> String) {
            self.activityTabNoEditsTitle = activityTabNoEditsTitle
            self.getActivityTabSaveTitle = getActivityTabSaveTitle
            self.getActivityTabReadTitle = getActivityTabReadTitle
            self.getActivityTabsEditTitle = getActivityTabsEditTitle
            self.tabTitle = tabTitle
            self.getGreeting = getGreeting
        }
    }
}

public struct ActivityItem {
    let type: ActivityTabDisplayType
    
    var imageName: String {
        switch type {
        case .edit, .noEdit, .addImage:
            return "activity-edit"
        case .read:
            return "activity-read"
        case .save:
            return "activity-save"
        }
    }
}

public enum ActivityTabDisplayType {
    case edit(Int)
    case read(Int)
    case save(Int)
    case noEdit
    case addImage
}
