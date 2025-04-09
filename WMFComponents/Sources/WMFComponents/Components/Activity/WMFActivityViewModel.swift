import Foundation
import SwiftUI
import WMFData

public class WMFActivityViewModel: ObservableObject {
    var activityItems: [ActivityItem]?
    var shouldShowAddAnImage: Bool
    var shouldShowStartEditing: Bool
    var hasNoEdits: Bool
    
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
    
    public init(activityItems: [ActivityItem]? = nil, shouldShowAddAnImage: Bool, shouldShowStartEditing: Bool, hasNoEdits: Bool) {
        self.activityItems = activityItems
        self.shouldShowAddAnImage = shouldShowAddAnImage
        self.shouldShowStartEditing = shouldShowStartEditing
        self.hasNoEdits = hasNoEdits
    }
}

public struct ActivityItem {
    let imageName: String
    let title: String
    let subtitle: String
    let onViewTitle: String
    let onViewTap: () -> Void
}
