import Foundation

/// Hashtags appended to edit summaries throughout the app, for identification in mediawiki history.
public enum WKEditSummaryTag: String {
    case articleSectionSourceEditor = "#article-section-source-editor"
    case articleFullSourceEditor = "#article-full-source-editor"
    case articleSelectSourceEditor = "#article-select-source-editor"
    case talkFullSourceEditor = "#talk-full-source-editor"
    case articleDescriptionAdd = "#article-add-desc"
    case articleDescriptionChange = "#article-change-desc"
    case articleHistoryDiffUndo = "#article-history-diff-undo"
    case articleHistoryDiffRollback = "#article-history-diff-rollback"
    case otherDiffUndo = "#other-diff-undo"
    case otherDiffRollback = "#other-diff-rollback"
    case watchlistDiffUndo = "#watchlist-diff-undo"
    case watchlistDiffRollback = "#watchlist-diff-rollback"
    case talkReply = "#talk-reply"
    case talkTopic = "#talk-topic"
}
