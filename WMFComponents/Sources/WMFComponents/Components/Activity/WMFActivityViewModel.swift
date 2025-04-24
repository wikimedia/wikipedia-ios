import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityViewModel: NSObject, ObservableObject {
    @Published var activityItems: [ActivityItem]?
    @Published public var isLoggedIn: Bool
    @Published public var project: WMFProject?
    var username: String
    var shouldShowAddAnImage: Bool
    var shouldShowStartEditing: Bool
    var hasNoEdits: Bool
    let openHistory: () -> Void
    @Published public var loginAction: (() -> Void)?
    let openSavedArticles: () -> Void
    let openSuggestedEdits: (() -> Void)?
    let openStartEditing: (() -> Void)?
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
            username: String,
            shouldShowAddAnImage: Bool,
            shouldShowStartEditing: Bool,
            hasNoEdits: Bool,
            openHistory: @escaping () -> Void,
            openSavedArticles: @escaping () -> Void,
            openSuggestedEdits: (() -> Void)?,
            openStartEditing: (() -> Void)?,
            loginAction: (() -> Void)?,
            isLoggedIn: Bool) {
        self.username = username
        self.activityItems = activityItems
        self.shouldShowAddAnImage = shouldShowAddAnImage
        self.shouldShowStartEditing = shouldShowStartEditing
        self.hasNoEdits = hasNoEdits
        self.openHistory = openHistory
        self.loginAction = loginAction
        self.openSavedArticles = openSavedArticles
        self.localizedStrings = localizedStrings
        self.isLoggedIn = isLoggedIn
        self.openSuggestedEdits = openSuggestedEdits
        self.openStartEditing = openStartEditing
    }
    
    func title(for type: ActivityTabDisplayType) -> String {
        switch type {
        case .edit:
            return localizedStrings.activityTabsEditTitle
        case .read:
            return localizedStrings.activityTabReadTitle
        case .save:
            return localizedStrings.activityTabSaveTitle
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
    
    func iconColor(for type: ActivityTabDisplayType) -> UIColor {
        switch type {
        case .edit, .noEdit, .addImage:
            theme.editorBlue
        case .save:
            theme.editorGreen
        case .read:
            theme.editorOrange
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

    public struct LocalizedStrings {
        let activityTabNoEditsTitle: String
        let activityTabSaveTitle: String
        let activityTabReadTitle: String
        let activityTabsEditTitle: String
        let tabTitle: String
        let greeting: String

        public init(activityTabNoEditsTitle: String, activityTabSaveTitle: String, activityTabReadTitle: String, activityTabsEditTitle: String, tabTitle: String, greeting: String) {
            self.activityTabNoEditsTitle = activityTabNoEditsTitle
            self.activityTabSaveTitle = activityTabSaveTitle
            self.activityTabReadTitle = activityTabReadTitle
            self.activityTabsEditTitle = activityTabsEditTitle
            self.tabTitle = tabTitle
            self.greeting = greeting
        }
    }
}

public struct ActivityItem {
    let title: String
    let subtitle: String?
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
    case edit
    case read
    case save
    case noEdit
    case addImage
}
