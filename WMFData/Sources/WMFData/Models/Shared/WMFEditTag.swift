import Foundation

/// Edit tags added to all MediaWiki API edit calls
public enum WMFEditTag: String {
    case appSuggestedEdit = "app-suggestededit"
    case appImageAddTop = "app-image-add-top"
    case appUndo = "app-undo"
    case appRollback = "app-rollback"
    case appDescriptionAdd = "app-description-add"
    case appDescriptionChange = "app-description-change"
    case appSectionSource = "app-section-source"
    case appFullSource = "app-full-source"
    case appSelectSource = "app-select-source"
    case appTalkSource = "app-talk-source"
    case appTalkReply = "app-talk-reply"
    case appTalkTopic = "app-talk-topic"
}
