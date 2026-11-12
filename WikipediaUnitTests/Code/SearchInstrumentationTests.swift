import XCTest
import WMFData
import WMFTestKitchen
import WMFComponents
@testable import Wikipedia

@MainActor
final class SearchInstrumentationTests: XCTestCase {

    private var sender: RecordingEventSender!
    /// The instrument keeps a weak reference to the client, so the test keeps it alive.
    private var client: TestKitchenClient!
    private var instrumentation: SearchInstrumentation!
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "fr", languageVariantCode: nil))

    override func setUp() async throws {
        try await super.setUp()
        sender = RecordingEventSender()
        client = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: sender)
        instrumentation = SearchInstrumentation(client: client)
        instrumentation.logSearchInit(searchTerm: "qu'est-ce que la communication", project: project)
        sender.events.removeAll()
    }

    func testExperimentExposureHasNoInstrumentAndNoFunnel() throws {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB
        defer { WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = nil }

        instrumentation.logExperimentExposure()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "experiment_exposure")
        XCTAssertNil(event.instrumentName)
        XCTAssertNil(event.funnelName)
        XCTAssertNil(event.actionSource)
        XCTAssertEqual(event.experimentData?.enrolled, "semantic-search-phase-2")
        XCTAssertEqual(event.experimentData?.assigned, "treatment")
        XCTAssertEqual(event.mediawikiData?.database, "frwiki")
    }

    func testSendingTheExposureMarksItSent() throws {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB
        defer { WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = nil }

        instrumentation.logExperimentExposure()

        XCTAssertTrue(WMFSemanticSearchDataController.shared.hasSentExposure)
    }

    func testExperimentExposureNeedsAGroup() throws {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = nil

        instrumentation.logExperimentExposure()

        XCTAssertTrue(sender.events.isEmpty)
    }

    func testDisabledInstrumentationSendsNothing() throws {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB
        defer { WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = nil }
        let editorSearch = SearchInstrumentation(client: client, isEnabled: false)

        editorSearch.logSearchScreenImpression(source: .editor, project: project)
        editorSearch.logSearchInit(searchTerm: "la lune", project: project)
        editorSearch.logLexicalResultsImpression(searchIDs: SearchInstrumentation.LexicalSearchIDs(prefix: "pre", fullText: "ful"))
        editorSearch.logSearchClose()
        editorSearch.logSearchBack()
        editorSearch.logExperimentExposure()

        XCTAssertTrue(sender.events.isEmpty)
    }

    func testEachSearchActivationStartsAFunnel() throws {
        sender.events.removeAll()
        let fresh = SearchInstrumentation(client: client)

        fresh.logSearchScreenImpression(source: .article, project: project)
        fresh.logSearchScreenImpression(source: .topOfFeed)
        fresh.logSearchScreenImpression(source: .searchTab)
        fresh.logSearchScreenImpression(source: .unknown)

        XCTAssertEqual(sender.events.map(\.action), ["impression", "impression", "impression", "impression"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["toolbar", "feed_bar", "nav_menu", nil])
        XCTAssertEqual(Set(sender.events.compactMap(\.funnelEntryToken)).count, 4)
        XCTAssertEqual(sender.events.map(\.funnelEventSequencePosition), [1, 1, 1, 1])
        XCTAssertNotNil(try context(of: sender.events[0])["time_spent_ms"])
        XCTAssertEqual(sender.events.map(\.mediawikiData?.database), ["frwiki", "frwiki", "frwiki", "frwiki"])
    }

    func testSearchInitCarriesTheQueryAndCutsLongOnes() throws {
        instrumentation.logSearchInit(searchTerm: "la lune", project: project)
        let longTerm = String(repeating: "x", count: SearchInstrumentation.queryLimit + 1)
        instrumentation.logSearchInit(searchTerm: longTerm, project: project)

        XCTAssertEqual(sender.events.map(\.action), ["init", "init"])
        let short = try context(of: sender.events[0])
        XCTAssertEqual(short["query"], "la lune")
        XCTAssertEqual(short["query_trunc"], "false")
        let long = try context(of: sender.events[1])
        XCTAssertEqual(long["query"]?.count, SearchInstrumentation.queryLimit)
        XCTAssertEqual(long["query_trunc"], "true")
    }

    func testLexicalResultsCarryBothSearchIDs() throws {
        let ids = SearchInstrumentation.LexicalSearchIDs(prefix: "pre", fullText: "ful")
        instrumentation.logLexicalResultsImpression(searchIDs: ids)
        instrumentation.logLexicalResultTap(position: 3, type: .full, searchIDs: ids)
        instrumentation.logLexicalResultTap(position: 1, type: .prefix, searchIDs: SearchInstrumentation.LexicalSearchIDs(prefix: "pre", fullText: nil))

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click"])
        XCTAssertEqual(sender.events.map(\.elementId), ["search_result", "search_result", "search_result"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["lexical_result", "lexical_result", "lexical_result"])

        let impression = try context(of: sender.events[0])
        XCTAssertEqual(impression["search_id_pre"], "pre")
        XCTAssertEqual(impression["search_id_ful"], "ful")
        XCTAssertNil(impression["search_id_sem"])

        let fullTextTap = try context(of: sender.events[1])
        XCTAssertEqual(fullTextTap["position"], "3")
        XCTAssertEqual(fullTextTap["type"], "FULL_TEXT")

        let prefixTap = try context(of: sender.events[2])
        XCTAssertEqual(prefixTap["type"], "PREFIX")
        XCTAssertNil(prefixTap["search_id_ful"])
    }

    func testTheOriginOfTheSearchIsTheSubtypeOfTheInit() throws {
        instrumentation.logSearchInit(searchTerm: "la lune", project: project, origin: .recentSearch)
        instrumentation.logSearchInit(searchTerm: "la lune rousse", project: project)
        instrumentation.logSearchInit(searchTerm: "la lune bleue", project: project, origin: .voice)

        XCTAssertEqual(sender.events.map(\.action), ["init", "init", "init"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["recent_search", nil, "voice"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, nil, nil])
        XCTAssertEqual(try context(of: sender.events[0])["query"], "la lune")
    }

    func testEventsShareTheFunnelOfTheSearch() throws {
        instrumentation.logEntryPointTap(isTryItNow: false)
        instrumentation.logResultsImpression(searchID: "abc")

        let events = sender.events
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.map(\.funnelName), ["search", "search"])
        XCTAssertEqual(events[0].funnelEntryToken, events[1].funnelEntryToken)
        // The init of the search in setUp is the first event of the funnel.
        XCTAssertEqual(events.map(\.funnelEventSequencePosition), [2, 3])
        XCTAssertEqual(events.map(\.instrumentName), ["apps-search", "apps-search"])
        XCTAssertEqual(events.map(\.actionSource), ["search", "search"])
        XCTAssertEqual(events.map(\.mediawikiData?.database), ["frwiki", "frwiki"])
    }

    func testTheFunnelHoldsEverySearchAndEveryReturnUntilTheSearchEnds() throws {
        sender.events.removeAll()
        let fresh = SearchInstrumentation(client: client)
        let ids = SearchInstrumentation.LexicalSearchIDs(prefix: "pre", fullText: nil)
        fresh.logSearchScreenImpression(source: .searchTab, project: project)
        fresh.logSearchInit(searchTerm: "la", project: project)
        fresh.logSearchInit(searchTerm: "la lune", project: project)
        fresh.logLexicalResultsImpression(searchIDs: ids)
        fresh.logLexicalResultTap(position: 1, type: .prefix, searchIDs: ids)
        fresh.logFeedbackSubmit(placement: .article, rating: .positive, text: nil, searchID: nil)
        fresh.logSearchInit(searchTerm: "la lune rousse", project: project)
        fresh.logLexicalResultsImpression(searchIDs: ids)
        fresh.endSearch()
        fresh.logSearchScreenImpression(source: .searchTab, project: project)
        fresh.logSearchInit(searchTerm: "le soleil", project: project)

        let tokens = sender.events.map(\.funnelEntryToken)
        XCTAssertEqual(Set(tokens[0...7]).count, 1)
        XCTAssertEqual(tokens[8], tokens[9])
        XCTAssertNotEqual(tokens[7], tokens[8])
        XCTAssertEqual(sender.events.map(\.funnelEventSequencePosition), [1, 2, 3, 4, 5, 6, 7, 8, 1, 2])
    }

    func testEntryPointClicks() throws {
        instrumentation.logEntryPointTap(isTryItNow: true)
        instrumentation.logEntryPointTap(isTryItNow: false)
        instrumentation.logEntryPointInfoTap()
        instrumentation.logEntryPointClose()

        XCTAssertEqual(sender.events.map(\.action), ["click", "click", "click", "click"])
        XCTAssertEqual(sender.events.map(\.elementId), ["try_now_button", "enter_semantic_search", "info_button", "close_semantic_button"])
        XCTAssertEqual(sender.events.compactMap(\.actionSubtype), [])
    }

    func testInfoSheetEvents() throws {
        instrumentation.logInfoImpression()
        instrumentation.logInfoClose()
        instrumentation.logInfoLearnMore()

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["feature_info", "feature_info", "feature_info"])
        XCTAssertEqual(sender.events.map(\.elementId), ["feature_info", "close_info_button", "learn_more_button"])
    }

    func testResultsImpressionAndTapCarryTheSearchID() throws {
        instrumentation.logResultsImpression(searchID: "abc")
        instrumentation.logResultTap(position: 2, searchID: "abc")
        instrumentation.logEmptyResultsImpression()

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "impression"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["semantic_result", "semantic_result", "semantic_result_empty"])
        XCTAssertEqual(sender.events.map(\.elementId), ["search_result", "search_result", "search_result"])

        let impression = try context(of: sender.events[0])
        XCTAssertEqual(impression["search_id_sem"], "abc")
        XCTAssertNotNil(impression["time_spent_ms"])

        let tap = try context(of: sender.events[1])
        XCTAssertEqual(tap["search_id_sem"], "abc")
        XCTAssertEqual(tap["position"], "2")
        XCTAssertEqual(tap["type"], "SEMANTIC")
    }

    func testClosingTheSheetIsNeverAFeedbackClose() throws {
        instrumentation.logResultsClose()

        XCTAssertEqual(sender.events.map(\.actionSubtype), ["semantic_result"])
        XCTAssertEqual(sender.events.map(\.elementId), ["close_result_button"])
    }

    func testFeedbackSubmitInTheSheetAndInTheArticle() throws {
        instrumentation.logFeedbackSubmit(placement: .sheet, rating: .positive, text: "  merci  ", searchID: "abc")
        instrumentation.logFeedbackSubmit(placement: .article, rating: .negative, text: nil, searchID: "abc")

        XCTAssertEqual(sender.events.map(\.action), ["click", "click"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["cardview_result", "article_result"])
        XCTAssertEqual(sender.events.map(\.elementId), ["feedback_submit", "feedback_submit"])

        let sheet = try context(of: sender.events[0])
        XCTAssertEqual(sheet["score"], "1")
        XCTAssertEqual(sheet["text"], "  merci  ")
        XCTAssertEqual(sheet["search_id_sem"], "abc")
        XCTAssertEqual(sheet["type"], "SEMANTIC")

        let article = try context(of: sender.events[1])
        XCTAssertEqual(article["score"], "0")
        XCTAssertNil(article["text"])
    }

    func testFeedbackTextIsCutToTheLimit() throws {
        let longText = String(repeating: "a", count: SearchInstrumentation.feedbackTextLimit + 20)
        instrumentation.logFeedbackSubmit(placement: .article, rating: .positive, text: longText, searchID: nil)

        let context = try context(of: sender.events[0])
        XCTAssertEqual(context["text"]?.count, SearchInstrumentation.feedbackTextLimit)
        XCTAssertNil(context["search_id_sem"])
    }

    func testFeedbackCloseAndSuppressedPrompt() throws {
        instrumentation.logFeedbackClose(placement: .article)
        instrumentation.logFeedbackPromptSuppressed(placement: .article, reason: .leftArticle)
        instrumentation.logFeedbackPromptSuppressed(placement: .article, reason: .startedActivity)
        instrumentation.logFeedbackPromptSuppressed(placement: .article, reason: .screenCovered)

        XCTAssertEqual(sender.events.map(\.action), ["click", "error", "error", "error"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["article_result", "article_result", "article_result", "article_result"])
        XCTAssertEqual(sender.events.map(\.elementId), ["close_feedback_button", "feedback_prompt", "feedback_prompt", "feedback_prompt"])
        XCTAssertEqual(try sender.events[1...].map { try context(of: $0)["error_type"] }, ["left_article", "started_activity", "screen_covered"])
    }

    // MARK: - Feedback prompt

    func testFeedbackPromptShowsOnceInTheSheetAndOnceInTheArticlePerFunnel() {
        XCTAssertTrue(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        instrumentation.feedbackPromptDidAppear(placement: .sheet)

        // The reader ignored the sheet and opened a passage.
        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        XCTAssertTrue(instrumentation.canShowFeedbackPrompt(placement: .article))
        instrumentation.feedbackPromptDidAppear(placement: .article)

        // Back in the same funnel: no prompt anywhere.
        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .article))
    }

    func testTheSheetDoesNotAskAfterTheArticleAsked() {
        instrumentation.feedbackPromptDidAppear(placement: .article)

        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .sheet))
    }

    func testAnAnswerEndsTheFeedbackPromptOfTheFunnel() {
        instrumentation.feedbackPromptDidAppear(placement: .sheet)
        instrumentation.logFeedbackSubmit(placement: .sheet, rating: .positive, text: nil, searchID: nil)

        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .article))
    }

    func testANewSearchCanShowTheFeedbackPromptAgain() {
        instrumentation.feedbackPromptDidAppear(placement: .sheet)
        instrumentation.feedbackPromptDidAppear(placement: .article)

        // The reader cancelled, then focused the search field again: a new funnel.
        instrumentation.endSearch()
        instrumentation.logSearchScreenImpression(source: .searchTab)

        XCTAssertTrue(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        XCTAssertTrue(instrumentation.canShowFeedbackPrompt(placement: .article))
    }

    func testTheFeedbackPromptStaysWithItsSearchAcrossQuestions() {
        instrumentation.feedbackPromptDidAppear(placement: .sheet)

        // Another question in the same search: more inits and a new list, same funnel.
        instrumentation.logSearchInit(searchTerm: "la lune", project: project)
        instrumentation.logLexicalResultsImpression(searchIDs: SearchInstrumentation.LexicalSearchIDs(prefix: nil, fullText: nil))

        XCTAssertFalse(instrumentation.canShowFeedbackPrompt(placement: .sheet))
        XCTAssertTrue(instrumentation.canShowFeedbackPrompt(placement: .article))
    }

    func testSettingsToggleHasNoFunnel() throws {
        SearchInstrumentation.logSettingsToggle(isOn: true, instrument: client.getInstrument(name: SearchInstrumentation.instrumentName))
        SearchInstrumentation.logSettingsToggle(isOn: false, instrument: client.getInstrument(name: SearchInstrumentation.instrumentName))

        XCTAssertEqual(sender.events.map(\.action), ["enable", "disable"])
        XCTAssertEqual(sender.events.map(\.actionSource), ["settings", "settings"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["semantic_search", "semantic_search"])
        XCTAssertEqual(sender.events.compactMap(\.funnelName), [])
    }

    private func context(of event: Event) throws -> [String: String] {
        let data = try XCTUnwrap(event.actionContext?.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }
}

private final class RecordingEventSender: EventSender {
    var events: [Event] = []

    func sendEvents(_ events: [Event]) {
        self.events.append(contentsOf: events)
    }
}

private struct EmptyClientData: ClientDataCallback {
    func getAgentData() -> AgentData? { nil }
    func getMediawikiData() -> MediawikiData? { nil }
    func getPerformerData() -> PerformerData? { nil }
}
