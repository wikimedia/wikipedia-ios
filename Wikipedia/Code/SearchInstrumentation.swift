import Foundation
import WMF
import WMFComponents
import WMFData
import WMFTestKitchen
import CocoaLumberjackSwift

/// Sends the events of the search funnel to the `apps-search` instrument. One instance follows a
/// search from the search screen, through the sheet of passages, to the feedback card in the
/// article, so every event shares the funnel of the search that started it.
@MainActor
final class SearchInstrumentation {

    /// Why the feedback card in the article did not get on screen. The names go out as
    /// `error_type` and must match Android.
    enum FeedbackSuppression: String {
        /// The reader left the article before the card was due.
        case leftArticle = "left_article"
        /// The reader started something else in the article: find in page, share, and so on.
        case startedActivity = "started_activity"
        /// Another screen was on top when the card was due.
        case screenCovered = "screen_covered"
    }

    /// How the search term got into the search bar. It goes out as the subtype of the init event.
    enum SearchOrigin {
        case typed
        case recentSearch
        case voice

        fileprivate var actionSubtype: String? {
            switch self {
            case .typed: return nil
            case .recentSearch: return "recent_search"
            case .voice: return "voice"
            }
        }
    }

    enum FeedbackPlacement {
        case sheet
        case article

        fileprivate var actionSubtype: String {
            switch self {
            case .sheet: return "cardview_result"
            case .article: return "article_result"
            }
        }
    }

    /// The ids of the lexical requests that gave the results on screen.
    struct LexicalSearchIDs {
        let prefix: String?
        let fullText: String?

        fileprivate var actionContext: [String: Any] {
            var context: [String: Any] = [:]
            if let prefix {
                context["search_id_pre"] = prefix
            }
            if let fullText {
                context["search_id_ful"] = fullText
            }
            return context
        }
    }

    static let instrumentName = "apps-search"
    /// The spec collects the search term up to this many characters.
    static let queryLimit = 256
    /// The text field already stops at this limit. The event cuts the text too, as a safety net.
    static let feedbackTextLimit = WMFSemanticSearchFeedbackViewModel.textLimit

    private static let funnelName = "search"
    private static let actionSource = "search"
    private static let semanticResultType = "SEMANTIC"

    private let client: TestKitchenClient
    private let instrument: InstrumentImpl
    private let dataController: WMFSemanticSearchDataController
    private let interleavedDataController: WMFSemanticSearchInterleavedDataController
    /// Off for searches that are not reading, like picking a link target in the editor. Then
    /// nothing goes out.
    private let isEnabled: Bool
    private(set) var project: WMFProject?

    /// What the feedback prompt did in the current funnel.
    private var feedbackPromptRecord = FeedbackPromptRecord(funnelToken: nil)

    init(client: TestKitchenClient = TestKitchenAdapter.shared.client, dataController: WMFSemanticSearchDataController = .shared, interleavedDataController: WMFSemanticSearchInterleavedDataController = .shared, isEnabled: Bool = true) {
        self.client = client
        self.instrument = client.getInstrument(name: Self.instrumentName)
        self.dataController = dataController
        self.interleavedDataController = interleavedDataController
        self.isEnabled = isEnabled
    }

    // MARK: - Experiment

    /// The reader could see the feature. Sent once per install, with no instrument and outside
    /// the search funnel, on the wiki of the search. Call it when `shouldSendExposure` says so.
    func logExperimentExposure() {
        guard isEnabled, let experimentData = dataController.experimentData else { return }
        client.submitExperimentExposure(experimentData: experimentData, mediawikiDatabase: project?.mediaWikiDatabase)
        do {
            try dataController.markExposureSent()
        } catch {
            DDLogError("Recording the semantic search exposure failed: \(error)")
        }
    }

    // MARK: - Search screen

    /// The search became active. A funnel starts here and holds everything the reader does
    /// from this search: every init, the result taps, the Dive sheet and the feedback in the
    /// article, also after a return from an article. It ends with `endSearch`. This is the
    /// life of a SearchActivity on Android. `project` is the wiki the search bar is set to.
    func logSearchScreenImpression(source: SearchResultsViewController.EventLoggingSource, project: WMFProject? = nil) {
        if let project {
            self.project = project
        }
        instrument.startFunnel(name: Self.funnelName)
        submit(action: "impression", actionSubtype: source.searchActionSubtype)
    }

    /// The reader tapped Cancel, or the back chevron on iPad. Send it before `endSearch`, so it
    /// stays in the funnel of the search.
    func logSearchBack() {
        submit(action: "click", elementId: "search_back")
    }

    /// The reader tapped the clear button in the search bar. The search stays active.
    func logSearchClose() {
        submit(action: "click", elementId: "search_close")
    }

    /// The reader cancelled the search or left the screen without opening an article. The next
    /// search starts a new funnel.
    func endSearch() {
        instrument.stopFunnel()
    }

    /// A search goes to the server. Every debounced search sends one, in the funnel of the
    /// screen. A search from a recent search or from dictation says so in the subtype.
    func logSearchInit(searchTerm: String, project: WMFProject, origin: SearchOrigin = .typed) {
        self.project = project
        if instrument.funnel == nil {
            instrument.startFunnel(name: Self.funnelName)
        }
        submit(action: "init", actionSubtype: origin.actionSubtype, actionContext: Self.queryContext(searchTerm))
    }

    // MARK: - Lexical results

    func logLexicalResultsImpression(searchIDs: LexicalSearchIDs) {
        submit(action: "impression", actionSubtype: "lexical_result", elementId: "search_result", actionContext: searchIDs.actionContext)
    }

    /// `position` starts at 1 for the first row.
    func logLexicalResultTap(position: Int, type: WMFSearchType, searchIDs: LexicalSearchIDs) {
        var actionContext = searchIDs.actionContext
        actionContext["position"] = position
        actionContext["type"] = type.searchResultType
        submit(action: "click", actionSubtype: "lexical_result", elementId: "search_result", actionContext: actionContext)
    }

    // MARK: - Entry point

    func logEntryPointTap(isTryItNow: Bool) {
        submit(action: "click", elementId: isTryItNow ? "try_now_button" : "enter_semantic_search")
    }

    func logEntryPointInfoTap() {
        submit(action: "click", elementId: "info_button")
    }

    func logEntryPointClose() {
        submit(action: "click", elementId: "close_semantic_button")
    }

    // MARK: - Info sheet

    func logInfoImpression() {
        submit(action: "impression", actionSubtype: "feature_info", elementId: "feature_info")
    }

    func logInfoClose() {
        submit(action: "click", actionSubtype: "feature_info", elementId: "close_info_button")
    }

    func logInfoLearnMore() {
        submit(action: "click", actionSubtype: "feature_info", elementId: "learn_more_button")
    }

    // MARK: - Sheet of passages

    func logResultsImpression(searchID: String?) {
        submit(action: "impression", actionSubtype: "semantic_result", elementId: "search_result", actionContext: searchIDContext(searchID))
    }

    func logEmptyResultsImpression() {
        submit(action: "impression", actionSubtype: "semantic_result_empty", elementId: "search_result")
    }

    /// The reader closed the sheet, also while it asks for feedback: that is a search with no
    /// click through, not a close of the feedback.
    func logResultsClose() {
        submit(action: "click", actionSubtype: "semantic_result", elementId: "close_result_button")
    }

    func logResultTap(position: Int, searchID: String?) {
        var actionContext = searchIDContext(searchID)
        actionContext["position"] = position
        actionContext["type"] = Self.semanticResultType
        submit(action: "click", actionSubtype: "semantic_result", elementId: "search_result", actionContext: actionContext)
    }

    // MARK: - Feedback

    func logFeedbackSubmit(placement: FeedbackPlacement, rating: WMFSemanticSearchFeedbackViewModel.Rating, text: String?, searchID: String?) {
        var actionContext = searchIDContext(searchID)
        actionContext["score"] = rating == .positive ? 1 : 0
        actionContext["type"] = Self.semanticResultType
        if let text, !text.isEmpty {
            actionContext["text"] = String(text.prefix(Self.feedbackTextLimit))
        }
        submit(action: "click", actionSubtype: placement.actionSubtype, elementId: "feedback_submit", actionContext: actionContext)
        updateFeedbackPromptRecord { $0.hasAnswer = true }
    }

    func logFeedbackClose(placement: FeedbackPlacement) {
        submit(action: "click", actionSubtype: placement.actionSubtype, elementId: "close_feedback_button")
    }

    /// The prompt did not get on screen: something else took the reader's attention first.
    func logFeedbackPromptSuppressed(placement: FeedbackPlacement, reason: FeedbackSuppression) {
        submit(action: "error", actionSubtype: placement.actionSubtype, elementId: "feedback_prompt", actionContext: ["error_type": reason.rawValue])
    }

    // MARK: - Feedback prompt

    /// What the feedback prompt did in one funnel. The record follows the funnel token, so it
    /// starts over whenever a new funnel starts, wherever that happens.
    private struct FeedbackPromptRecord {
        let funnelToken: String?
        var hasShownInSheet = false
        var hasShownInArticle = false
        var hasAnswer = false
    }

    private var currentFeedbackPromptRecord: FeedbackPromptRecord {
        let funnelToken = instrument.funnel?.token
        guard feedbackPromptRecord.funnelToken == funnelToken else {
            return FeedbackPromptRecord(funnelToken: funnelToken)
        }
        return feedbackPromptRecord
    }

    private func updateFeedbackPromptRecord(_ update: (inout FeedbackPromptRecord) -> Void) {
        var record = currentFeedbackPromptRecord
        update(&record)
        feedbackPromptRecord = record
    }

    /// The prompt shows at most once in the sheet and once in the article per funnel, and never
    /// after an answer, so a funnel has at most one answer. The sheet doesn't ask again after the
    /// article asked. Only a prompt that got on screen counts.
    func canShowFeedbackPrompt(placement: FeedbackPlacement) -> Bool {
        let record = currentFeedbackPromptRecord
        switch placement {
        case .sheet:
            return !record.hasShownInSheet && !record.hasShownInArticle && !record.hasAnswer
        case .article:
            return !record.hasShownInArticle && !record.hasAnswer
        }
    }

    func feedbackPromptDidAppear(placement: FeedbackPlacement) {
        updateFeedbackPromptRecord { record in
            switch placement {
            case .sheet:
                record.hasShownInSheet = true
            case .article:
                record.hasShownInArticle = true
            }
        }
    }

    // MARK: - Settings

    static func logSettingsToggle(isOn: Bool, instrument: InstrumentImpl = TestKitchenAdapter.shared.client.getInstrument(name: instrumentName), dataController: WMFSemanticSearchDataController = .shared) {
        instrument.submitInteraction(
            action: isOn ? "enable" : "disable",
            actionSource: "settings",
            actionSubtype: "semantic_search",
            experimentData: dataController.experimentData
        )
    }

    // MARK: - Semantic search interleaved

    // TODO: Still to be settled. The event names, `action_context` keys and attempt outcomes below are
    // provisional and follow the EF-3 acceptance criteria.

    /// The reader first entered a non-empty query on a target wiki, in either arm. Sent with the
    /// experiment data of the interleaved experiment, outside the search funnel.
    func logInterleavedExposure(arm: String, wiki: String) {
        guard isEnabled else { return }
        client.submitExperimentExposure(experimentData: interleavedExperimentData(arm: arm), mediawikiDatabase: wiki)
    }

    func logInterleavedQueryInput(_ attempt: WMFSemanticSearchInterleavedAttemptLog) {
        submitInterleaved(action: "query_input", arm: attempt.arm, wiki: attempt.wiki, actionContext: Self.interleavedAttemptContext(attempt))
    }

    func logInterleavedRetrievalEligible(_ attempt: WMFSemanticSearchInterleavedAttemptLog) {
        submitInterleaved(action: "retrieval_eligible", arm: attempt.arm, wiki: attempt.wiki, actionContext: Self.interleavedAttemptContext(attempt))
    }

    func logInterleavedRequestIssued(_ attempt: WMFSemanticSearchInterleavedAttemptLog, trigger: WMFSemanticSearchInterleavedTrigger) {
        var actionContext = Self.interleavedAttemptContext(attempt)
        actionContext["trigger"] = trigger.rawValue
        submitInterleaved(action: "init", actionSubtype: "interleaved_search", arm: attempt.arm, wiki: attempt.wiki, actionContext: actionContext)
    }

    func logInterleavedAttemptEnded(attemptID: String, outcome: WMFSemanticSearchInterleavedAttemptOutcome, arm: String, wiki: String) {
        submitInterleaved(action: "attempt_end", arm: arm, wiki: wiki, actionContext: [
            "attempt_id": attemptID,
            "outcome": outcome.rawValue,
            "arm": arm
        ])
    }

    /// The list rendered: one event for the list, then one impression for each result.
    func logInterleavedListRendered(list: WMFSemanticSearchInterleavedListLog, results: [WMFSemanticSearchInterleavedResultLog]) {
        var actionContext = Self.interleavedAttemptContext(WMFSemanticSearchInterleavedAttemptLog(attemptID: list.attemptID, query: list.query, wiki: list.wiki, deviceLanguage: list.deviceLanguage, arm: list.arm))
        actionContext["list_id"] = list.listID
        actionContext["merge_version"] = list.mergeVersion
        actionContext["lexical_version"] = list.lexicalVersion
        actionContext["seed"] = list.seed
        actionContext["coin_flips"] = list.coinFlips
        actionContext["list_length"] = list.listLength
        actionContext["result_count"] = results.count
        actionContext["interleave_state"] = list.interleaveState?.rawValue
        actionContext["trigger"] = list.trigger.rawValue
        actionContext["latency_lexical_ms"] = list.latency.lexicalMs
        actionContext["latency_semantic_ms"] = list.latency.semanticMs
        actionContext["latency_merge_ms"] = list.latency.mergeMs
        actionContext["latency_total_ms"] = list.latency.totalMs
        actionContext["search_id_pre"] = list.searchIDs.prefix
        actionContext["search_id_ful"] = list.searchIDs.fullText
        actionContext["search_id_sem"] = list.searchIDs.semantic
        actionContext["semantic_model"] = list.semanticModel
        actionContext["semantic_index_version"] = list.semanticIndexVersion
        submitInterleaved(action: "impression", actionSubtype: "interleaved_list", arm: list.arm, wiki: list.wiki, actionContext: actionContext)

        for result in results {
            submitInterleaved(action: "impression", actionSubtype: "\(result.team.rawValue)_result", elementId: "search_result", arm: list.arm, wiki: list.wiki, actionContext: Self.interleavedResultContext(list: list, result: result))
        }
    }

    /// `millisecondsSinceRender` is the time since the list rendered.
    func logInterleavedResultTap(list: WMFSemanticSearchInterleavedListLog, result: WMFSemanticSearchInterleavedResultLog, millisecondsSinceRender: Int) {
        var actionContext = Self.interleavedResultContext(list: list, result: result)
        actionContext["ms_since_render"] = millisecondsSinceRender
        submitInterleaved(action: "click", actionSubtype: "\(result.team.rawValue)_result", elementId: "search_result", arm: list.arm, wiki: list.wiki, actionContext: actionContext)
    }

    // MARK: - Private

    private static func queryContext(_ searchTerm: String) -> [String: Any] {
        let isTruncated = searchTerm.count > queryLimit
        return [
            "query": isTruncated ? String(searchTerm.prefix(queryLimit)) : searchTerm,
            "query_trunc": isTruncated
        ]
    }

    private func submit(action: String, actionSubtype: String? = nil, elementId: String? = nil, actionContext: [String: Any] = [:]) {
        guard isEnabled else { return }
        instrument.submitInteraction(
            action: action,
            actionSource: Self.actionSource,
            actionSubtype: actionSubtype,
            elementId: elementId,
            actionContext: actionContext.isEmpty ? nil : actionContext,
            mediawikiDatabase: project?.mediaWikiDatabase,
            experimentData: dataController.experimentData
        )
    }

    /// The experiment data of the interleaved experiment. The sandbox in developer settings sends arms
    /// that are not the reader's own, and goes out as forced.
    private func interleavedExperimentData(arm: String) -> ExperimentData {
        if let experimentData = interleavedDataController.experimentData, experimentData.assigned == arm {
            return experimentData
        }
        return ExperimentData(
            enrolled: WMFSemanticSearchInterleavedDataController.experimentName,
            assigned: arm,
            coordinator: ExperimentData.coordinatorForced,
            subjectId: WMFDataEnvironment.current.appInstallIDUtility?()
        )
    }

    private func submitInterleaved(action: String, actionSubtype: String? = nil, elementId: String? = nil, arm: String, wiki: String, actionContext: [String: Any]) {
        guard isEnabled else { return }
        instrument.submitInteraction(
            action: action,
            actionSource: Self.actionSource,
            actionSubtype: actionSubtype,
            elementId: elementId,
            actionContext: actionContext.isEmpty ? nil : actionContext,
            mediawikiDatabase: wiki,
            experimentData: interleavedExperimentData(arm: arm)
        )
    }

    /// The query features of an event: the text cut at the limit, the length in graphemes (counted on
    /// the full text), the wiki, the device language and the arm.
    private static func interleavedAttemptContext(_ attempt: WMFSemanticSearchInterleavedAttemptLog) -> [String: Any] {
        let isTruncated = attempt.query.count > queryLimit
        return [
            "attempt_id": attempt.attemptID,
            "query": isTruncated ? String(attempt.query.prefix(queryLimit)) : attempt.query,
            "query_trunc": isTruncated,
            "query_length": attempt.query.count,
            "wiki": attempt.wiki,
            "device_language": attempt.deviceLanguage,
            "arm": attempt.arm
        ]
    }

    /// An impression or a click of one result. `action_subtype` tells lexical from semantic on both.
    private static func interleavedResultContext(list: WMFSemanticSearchInterleavedListLog, result: WMFSemanticSearchInterleavedResultLog) -> [String: Any] {
        var actionContext: [String: Any] = [
            "list_id": list.listID,
            "arm": list.arm,
            "position": result.position,
            "page_id": result.details.pageID,
            "team": result.team.rawValue,
            "rank": result.rank,
            "also_in_other": result.alsoInOther
        ]
        actionContext["visible"] = result.details.isVisible
        actionContext["section"] = result.details.section
        actionContext["descriptor_type"] = result.details.descriptorType
        actionContext["thumbnail_present"] = result.details.hasThumbnail
        actionContext["score"] = result.details.score
        return actionContext
    }

    private func searchIDContext(_ searchID: String?) -> [String: Any] {
        guard let searchID else { return [:] }
        return ["search_id_sem": searchID]
    }
}

private extension SearchResultsViewController.EventLoggingSource {

    /// Where the reader came from, in the names of the spec.
    var searchActionSubtype: String? {
        switch self {
        case .article: return "toolbar"
        case .topOfFeed: return "feed_bar"
        case .searchTab: return "nav_menu"
        case .unknown, .editor: return nil
        }
    }
}

private extension WMFSearchType {

    var searchResultType: String {
        switch self {
        case .prefix: return "PREFIX"
        case .full: return "FULL_TEXT"
        }
    }
}

extension WMFProject {

    /// The MediaWiki database of the project, as the events name it (`frwiki`).
    var mediaWikiDatabase: String? {
        guard case .wikipedia(let language) = self else { return nil }
        return language.languageCode.replacingOccurrences(of: "-", with: "_") + "wiki"
    }
}
