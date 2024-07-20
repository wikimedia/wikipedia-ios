import Foundation

/// Hashtags appended to edit summaries throughout the app, for identification in mediawiki history.
@available(*, deprecated, message: "Please use WKEditTag instead.")
public enum WKEditSummaryTag: String {
    case articleSectionSourceEditor = "#article-section-source-editor"
    case articleFullSourceEditor = "#article-full-source-editor"
    case articleSelectSourceEditor = "#article-select-source-editor"
    case talkFullSourceEditor = "#talk-full-source-editor"
    case articleDescriptionAdd = "#article-add-desc"
    case articleDescriptionChange = "#article-change-desc"
    case diffUndo = "#diff-undo"
    case diffRollback = "#diff-rollback"
    case talkReply = "#talk-reply"
    case talkTopic = "#talk-topic"
    case suggestedEditsAddImageTop = "#app-image-add-top"
}

/// Edit tags added to all MediaWiki API edit calls
public enum WKEditTag: String {
    case appSuggestedEdit = "app-suggestededit"
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
