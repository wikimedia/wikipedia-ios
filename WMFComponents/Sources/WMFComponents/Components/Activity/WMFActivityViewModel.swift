import Foundation
import SwiftUI
import WMFData

@objc public class WMFActivityViewModel: NSObject, ObservableObject {
    @Published var activityItems: [ActivityItem]?
    @Published public var isLoggedIn: Bool
    @Published public var project: WMFProject?
    var shouldShowAddAnImage: Bool
    var shouldShowStartEditing: Bool
    var hasNoEdits: Bool
    let openHistory: () -> Void
    @Published public var loginAction: (() -> Void)?
    let openSavedArticles: () -> Void
    public var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    public var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    
    // TODO: Localize strings
    // No edits strings
    let noEditsTitle = "You haven't made any edits yet."
    let noEditsSubtitle = "Start editing to begin tracking your contributions."
    let noEditsButtonTitle = "Start editing"
    
    // Add an image strings
    let addAnImageButtonTitle = "Add"
    let addAnImageTitle = "Add images"
    let addAnImageSubtitle = "Add suggested images to Wikipedia articles to enhance understanding."
    
    let suggestedEdits = "Suggested edits"
    
    var localizedStrings: LocalizedStrings
    
    public init(
            localizedStrings: LocalizedStrings,
            activityItems: [ActivityItem]? = nil,
            shouldShowAddAnImage: Bool,
            shouldShowStartEditing: Bool,
            hasNoEdits: Bool,
            openHistory: @escaping () -> Void,
            openSavedArticles: @escaping () -> Void,
            loginAction: (() -> Void)?,
            isLoggedIn: Bool) {
        self.activityItems = activityItems
        self.shouldShowAddAnImage = shouldShowAddAnImage
        self.shouldShowStartEditing = shouldShowStartEditing
        self.hasNoEdits = hasNoEdits
        self.openHistory = openHistory
        self.loginAction = loginAction
        self.openSavedArticles = openSavedArticles
        self.localizedStrings = localizedStrings
        self.isLoggedIn = isLoggedIn
    }
    
    func title(for type: ActivityTabDisplayType) -> String? {
        switch type {
        case .edit:
            return nil
        case .read:
            return localizedStrings.activityTabViewReadingHistory
        case .save:
            return localizedStrings.activityTabViewSavedArticles
        }
    }
    
    func action(for type: ActivityTabDisplayType) -> (() -> Void)? {
        switch type {
        case .edit:
            return nil
        case .read:
            return openHistory
        case .save:
            return openSavedArticles
        }
    }
    
    public struct LocalizedStrings {
        let activityTabViewReadingHistory: String
        let activityTabViewSavedArticles: String
        
        public init(activityTabViewReadingHistory: String, activityTabViewSavedArticles: String) {
            self.activityTabViewReadingHistory = activityTabViewReadingHistory
            self.activityTabViewSavedArticles = activityTabViewSavedArticles
        }
    }
}

public struct ActivityItem {
    let imageName: String
    let title: String
    let type: ActivityTabDisplayType
    
    public init(imageName: String, title: String, type: ActivityTabDisplayType) {
        self.imageName = imageName
        self.title = title
        self.type = type
    }
}

public enum ActivityTabDisplayType {
    case edit
    case read
    case save
}
