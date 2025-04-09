import Foundation
import SwiftUI
import WMFData

public class WMFActivityViewModel: ObservableObject {
    @Published var activityItems: [ActivityItem]?
    var shouldShowAddAnImage: Bool
    var shouldShowStartEditing: Bool
    var hasNoEdits: Bool
    let openHistory: () -> Void
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
    
    public init(activityItems: [ActivityItem]? = nil, shouldShowAddAnImage: Bool, shouldShowStartEditing: Bool, hasNoEdits: Bool, openHistory: @escaping () -> Void) {
        self.activityItems = activityItems
        self.shouldShowAddAnImage = shouldShowAddAnImage
        self.shouldShowStartEditing = shouldShowStartEditing
        self.hasNoEdits = hasNoEdits
        self.openHistory = openHistory
    }
}

public struct ActivityItem {
    let imageName: String
    let title: String
    let subtitle: String
    let onViewTitle: String
    let onViewTap: () -> Void
    
    public init(imageName: String, title: String, subtitle: String, onViewTitle: String, onViewTap: @escaping () -> Void) {
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
        self.onViewTitle = onViewTitle
        self.onViewTap = onViewTap
    }
}
