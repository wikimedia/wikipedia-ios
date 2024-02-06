import Foundation

/// Hashtags appended to edit summaries throughout the app, for identification in mediawiki history.
public enum WKEditSummaryTag: String {
    case articleSectionSourceEditor = "#article_section_source_editor"
    case articleFullSourceEditor = "#article_full_source_editor"
    case articleSelectSourceEditor = "#article_seelct_source_editor"
    case talkFullSourceEditor = "#talk_full_source_editor"
    case articleDescriptionAdd = "#article_description_add"
    case articleDescriptionChange = "#article_description_change"
    case articleHistoryDiffUndo = "#article_history_diff_undo"
    case articleHistoryDiffRollback = "#article_history_diff_rollback"
    case otherDiffUndo = "#other_diff_undo"
    case otherDiffRollback = "#other_diff_rollback"
    case watchlistDiffUndo = "#watchlist_diff_undo"
    case watchlistDiffRollback = "#watchlist_diff_rollback"
    case talkReply = "#talk_reply"
    case talkTopic = "#talk_topic"
}
