import Foundation
import WMF
import WMFComponents
import WMFData
import WMFTestKitchen

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
    private(set) var project: WMFProject?

    init(client: TestKitchenClient = TestKitchenAdapter.shared.client, dataController: WMFSemanticSearchDataController = .shared) {
        self.client = client
        self.instrument = client.getInstrument(name: Self.instrumentName)
        self.dataController = dataController
    }

    // MARK: - Experiment

    /// The reader got a group. Sent once, with no instrument and outside the search funnel, on
    /// the wiki of the search that enrolled the reader.
    func logExperimentExposure() {
        guard let experimentData = dataController.experimentData else { return }
        client.submitExperimentExposure(experimentData: experimentData, mediawikiDatabase: project?.mediaWikiDatabase)
    }

    // MARK: - Search screen

    /// The reader got to the search screen. The funnel starts here, once per screen, and holds
    /// every search the reader runs on it, through the result taps and the feedback in the
    /// article. A new search screen has its own instrumentation, so its own funnel. `project`
    /// is the wiki the search bar is set to, when known.
    func logSearchScreenImpression(source: SearchResultsViewController.EventLoggingSource, project: WMFProject? = nil) {
        if let project {
            self.project = project
        }
        if instrument.funnel == nil {
            instrument.startFunnel(name: Self.funnelName)
        }
        submit(action: "impression", actionSubtype: source.searchActionSubtype)
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

    /// Closing the sheet while it asks for feedback counts as closing the feedback.
    func logResultsClose(whileAskingForFeedback: Bool) {
        if whileAskingForFeedback {
            logFeedbackClose(placement: .sheet)
        } else {
            submit(action: "click", actionSubtype: "semantic_result", elementId: "close_result_button")
        }
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
    }

    func logFeedbackClose(placement: FeedbackPlacement) {
        submit(action: "click", actionSubtype: placement.actionSubtype, elementId: "feedback_close_button")
    }

    /// The prompt did not get on screen: something else took the reader's attention first.
    func logFeedbackPromptSuppressed(placement: FeedbackPlacement, reason: FeedbackSuppression) {
        submit(action: "error", actionSubtype: placement.actionSubtype, elementId: "feedback_prompt", actionContext: ["error_type": reason.rawValue])
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

    // MARK: - Private

    private static func queryContext(_ searchTerm: String) -> [String: Any] {
        let isTruncated = searchTerm.count > queryLimit
        return [
            "query": isTruncated ? String(searchTerm.prefix(queryLimit)) : searchTerm,
            "query_trunc": isTruncated
        ]
    }

    private func submit(action: String, actionSubtype: String? = nil, elementId: String? = nil, actionContext: [String: Any] = [:]) {
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
        case .unknown: return nil
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

private extension WMFProject {

    /// The MediaWiki database of the project, as the events name it (`frwiki`).
    var mediaWikiDatabase: String? {
        guard case .wikipedia(let language) = self else { return nil }
        return language.languageCode.replacingOccurrences(of: "-", with: "_") + "wiki"
    }
}
