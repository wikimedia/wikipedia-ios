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

    // MARK: - Semantic search interleaved

    private struct InterleavedPage: Sendable { let id: Int }

    private func makeInterleavedMerge() -> WMFInterleaveResult<InterleavedPage> {
        // Page 2 is in both lists, so it is placed once and flagged as also in the other list.
        WMFSearchResultsInterleaver.merge(
            lexical: [InterleavedPage(id: 1), InterleavedPage(id: 2)],
            semantic: [InterleavedPage(id: 2), InterleavedPage(id: 3)],
            listLength: 10,
            seed: 7,
            pageID: { $0.id }
        )
    }

    private func makeInterleavedList(arm: String = "treatment", merge: WMFInterleaveResult<InterleavedPage>) -> WMFSemanticSearchInterleavedListLog {
        WMFSemanticSearchInterleavedListLog(
            listID: "list-1", attemptID: "attempt-1", query: "tour eiffel", wiki: "frwiki", deviceLanguage: "fr", arm: arm,
            mergeVersion: merge.mergeVersion, lexicalVersion: WMFLexicalListBuilder.lexicalVersion,
            seed: merge.seedLog, coinFlips: merge.coinFlipsLog, listLength: 10,
            interleaveState: .full, trigger: .pause,
            latency: WMFSemanticSearchInterleavedLatency(lexicalMs: 120, semanticMs: 340, mergeMs: 1, totalMs: 345),
            searchIDs: WMFSemanticSearchInterleavedIDs(prefix: "pre", fullText: nil, semantic: "sem"),
            semanticModel: "model-a", semanticIndexVersion: "2026-10"
        )
    }

    private func makeInterleavedResults(_ merge: WMFInterleaveResult<InterleavedPage>, visible: Bool = true) -> [WMFSemanticSearchInterleavedResultLog] {
        merge.resultLogs { slot in
            WMFSemanticSearchInterleavedResultDetails(pageID: slot.item.id, section: slot.item.id == 3 ? "History" : nil, score: 0.5, descriptorType: slot.item.id == 3 ? "passage" : "lead", hasThumbnail: true, isVisible: visible)
        }
    }

    func testInterleavedListRenderedHasOneListEventThenOneImpressionPerResult() throws {
        let merge = makeInterleavedMerge()

        instrumentation.logInterleavedListRendered(list: makeInterleavedList(merge: merge), results: makeInterleavedResults(merge))

        XCTAssertEqual(sender.events.count, 1 + merge.slots.count)
        XCTAssertEqual(sender.events[0].action, "impression")
        XCTAssertEqual(sender.events[0].actionSubtype, "interleaved_list")
        XCTAssertTrue(sender.events.dropFirst().allSatisfy { $0.action == "impression" && $0.elementId == "search_result" })
        XCTAssertTrue(sender.events.allSatisfy { $0.instrumentName == SearchInstrumentation.instrumentName && $0.actionSource == "search" })
        XCTAssertEqual(sender.events.map(\.mediawikiData?.database), Array(repeating: "frwiki", count: sender.events.count))
    }

    func testInterleavedListEventCarriesWhatAnalyticsNeedsToRebuildTheList() throws {
        let merge = makeInterleavedMerge()

        instrumentation.logInterleavedListRendered(list: makeInterleavedList(merge: merge), results: makeInterleavedResults(merge))

        let context = try context(of: sender.events[0])
        XCTAssertEqual(context["list_id"], "list-1")
        XCTAssertEqual(context["arm"], "treatment")
        XCTAssertEqual(context["merge_version"], "1")
        XCTAssertEqual(context["lexical_version"], "1")
        XCTAssertEqual(context["seed"], "7")
        XCTAssertEqual(context["coin_flips"], merge.coinFlipsLog)
        XCTAssertEqual(context["list_length"], "10")
        XCTAssertEqual(context["interleave_state"], "full")
        XCTAssertEqual(context["trigger"], "pause")
        XCTAssertEqual(context["search_id_pre"], "pre")
        XCTAssertEqual(context["search_id_sem"], "sem")
        XCTAssertNil(context["search_id_ful"], "No full text request, so the key is left out")
        XCTAssertEqual(context["latency_total_ms"], "345")
        XCTAssertEqual(context["semantic_model"], "model-a")
    }

    func testInterleavedControlListHasNoMergeFields() throws {
        let merge = makeInterleavedMerge()
        let control = WMFSemanticSearchInterleavedListLog(
            listID: "list-2", attemptID: "attempt-2", query: "tour", wiki: "frwiki", deviceLanguage: "fr", arm: "control",
            mergeVersion: nil, lexicalVersion: 1, seed: nil, coinFlips: nil, listLength: 10,
            interleaveState: nil, trigger: .submit,
            latency: WMFSemanticSearchInterleavedLatency(lexicalMs: 100, semanticMs: nil, mergeMs: 0, totalMs: 100),
            searchIDs: WMFSemanticSearchInterleavedIDs(prefix: "pre", fullText: nil, semantic: nil),
            semanticModel: nil, semanticIndexVersion: nil
        )

        instrumentation.logInterleavedListRendered(list: control, results: makeInterleavedResults(merge))

        let context = try context(of: sender.events[0])
        XCTAssertNil(context["interleave_state"], "The control arm has no state")
        XCTAssertNil(context["seed"])
        XCTAssertNil(context["coin_flips"])
        XCTAssertNil(context["merge_version"])
    }

    func testInterleavedResultImpressionsCarryTeamRankAndVisibility() throws {
        let merge = makeInterleavedMerge()

        instrumentation.logInterleavedListRendered(list: makeInterleavedList(merge: merge), results: makeInterleavedResults(merge, visible: false))

        let impressions = Array(sender.events.dropFirst())
        for (index, impression) in impressions.enumerated() {
            let slot = merge.slots[index]
            let context = try context(of: impression)
            XCTAssertEqual(impression.actionSubtype, "\(slot.searchType.rawValue)_result")
            XCTAssertEqual(context["position"], "\(index + 1)")
            XCTAssertEqual(context["page_id"], "\(slot.item.id)")
            XCTAssertEqual(context["team"], slot.searchType.rawValue)
            XCTAssertEqual(context["rank"], "\(slot.rank)")
            XCTAssertEqual(context["also_in_other"], "\(slot.alsoInOther)")
            XCTAssertEqual(context["visible"], "false")
            XCTAssertEqual(context["descriptor_type"], slot.item.id == 3 ? "passage" : "lead")
            XCTAssertEqual(context["thumbnail_present"], "true")
        }
        let three = try XCTUnwrap(impressions.first { (try? context(of: $0))?["page_id"] == "3" })
        XCTAssertEqual(try context(of: three)["section"], "History")
        let one = try XCTUnwrap(impressions.first { (try? context(of: $0))?["page_id"] == "1" })
        XCTAssertNil(try context(of: one)["section"])
    }

    func testInterleavedClickKeepsTheImpressionFieldsAndAddsTheTimeSinceRender() throws {
        let merge = makeInterleavedMerge()
        let list = makeInterleavedList(merge: merge)
        let result = try XCTUnwrap(makeInterleavedResults(merge).last)

        instrumentation.logInterleavedResultTap(list: list, result: result, millisecondsSinceRender: 1500)

        let click = try XCTUnwrap(sender.events.first)
        let context = try context(of: click)
        XCTAssertEqual(click.action, "click")
        XCTAssertEqual(click.actionSubtype, "\(result.team.rawValue)_result")
        XCTAssertEqual(click.elementId, "search_result")
        XCTAssertEqual(context["list_id"], "list-1")
        XCTAssertEqual(context["position"], "\(result.position)")
        XCTAssertEqual(context["ms_since_render"], "1500")
    }

    func testInterleavedQueryIsCutAtTheLimitButLengthIsCountedOnTheFullText() throws {
        let long = String(repeating: "é", count: 300)

        instrumentation.logInterleavedQueryInput(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: long, wiki: "frwiki", deviceLanguage: "fr", arm: "control"))

        let event = try XCTUnwrap(sender.events.first)
        let context = try context(of: event)
        XCTAssertEqual(event.action, "query_input")
        XCTAssertEqual(context["query"], String(repeating: "é", count: 256))
        XCTAssertEqual(context["query_trunc"], "true")
        XCTAssertEqual(context["query_length"], "300")
    }

    func testInterleavedQueryLengthCountsGraphemesNotScalars() throws {
        // A flag is two scalars and one grapheme. 日本 is two graphemes.
        instrumentation.logInterleavedRetrievalEligible(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: "🇫🇷日本", wiki: "jawiki", deviceLanguage: "ja", arm: "treatment"))

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "retrieval_eligible")
        XCTAssertEqual(try context(of: event)["query_length"], "3")
        XCTAssertEqual(try context(of: event)["query_trunc"], "false")
    }

    func testInterleavedRequestIssuedNamesTheTriggerAndAttemptEndNamesTheOutcome() throws {
        instrumentation.logInterleavedRequestIssued(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: "q", wiki: "frwiki", deviceLanguage: "fr", arm: "treatment"), trigger: .submit)
        instrumentation.logInterleavedAttemptEnded(attemptID: "a", outcome: .superseded, arm: "treatment", wiki: "frwiki")

        XCTAssertEqual(sender.events.map(\.action), ["init", "attempt_end"])
        XCTAssertEqual(sender.events[0].actionSubtype, "interleaved_search")
        XCTAssertEqual(try context(of: sender.events[0])["trigger"], "submit")
        XCTAssertEqual(try context(of: sender.events[1])["outcome"], "superseded")
        XCTAssertEqual(try context(of: sender.events[1])["attempt_id"], "a")
    }

    func testInterleavedEventsCarryTheExperimentDataOfTheInterleavedExperiment() throws {
        instrumentation.logInterleavedQueryInput(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: "q", wiki: "frwiki", deviceLanguage: "fr", arm: "treatment"))

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.experimentData?.enrolled, WMFSemanticSearchInterleavedDataController.experimentName)
        XCTAssertEqual(event.experimentData?.assigned, "treatment")
        XCTAssertEqual(event.experimentData?.coordinator, ExperimentData.coordinatorForced, "An arm that is not the reader's own goes out as forced")
    }

    func testInterleavedExposureHasNoInstrumentAndNoFunnel() throws {
        instrumentation.logInterleavedExposure(arm: "control", wiki: "frwiki")

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "experiment_exposure")
        XCTAssertNil(event.instrumentName)
        XCTAssertNil(event.funnelName)
        XCTAssertEqual(event.experimentData?.enrolled, WMFSemanticSearchInterleavedDataController.experimentName)
        XCTAssertEqual(event.experimentData?.assigned, "control")
        XCTAssertEqual(event.mediawikiData?.database, "frwiki")
    }

    func testDisabledInstrumentationSendsNoInterleavedEvents() {
        let editorSearch = SearchInstrumentation(client: client, isEnabled: false)

        editorSearch.logInterleavedExposure(arm: "treatment", wiki: "frwiki")
        editorSearch.logInterleavedQueryInput(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: "q", wiki: "frwiki", deviceLanguage: "fr", arm: "treatment"))
        editorSearch.logInterleavedAttemptEnded(attemptID: "a", outcome: .endedBeforeRequest, arm: "treatment", wiki: "frwiki")

        XCTAssertTrue(sender.events.isEmpty)
    }

    func testInterleavedEventsJoinTheFunnelOfTheSearch() throws {
        sender.events.removeAll()
        let fresh = SearchInstrumentation(client: client)
        fresh.logSearchScreenImpression(source: .searchTab, project: project)

        fresh.logInterleavedQueryInput(WMFSemanticSearchInterleavedAttemptLog(attemptID: "a", query: "q", wiki: "frwiki", deviceLanguage: "fr", arm: "treatment"))

        XCTAssertEqual(sender.events.count, 2)
        XCTAssertEqual(sender.events[0].funnelEntryToken, sender.events[1].funnelEntryToken)
        XCTAssertEqual(sender.events[1].funnelEventSequencePosition, 2)
    }

    // MARK: - Example payloads

    /// Generates the example payloads for the backend: what the app sends for each state of the
    /// interleaved search experiment. The lists are fixtures with fake pages and fixed IDs, seed and
    /// latencies. It writes a file only when `EXAMPLE_PAYLOADS_PATH` is set, so a normal test run
    /// changes nothing:
    ///
    ///     TEST_RUNNER_EXAMPLE_PAYLOADS_PATH=/path/payloads.json xcodebuild test ... \
    ///         -only-testing:WikipediaUnitTests/SearchInstrumentationTests/testWritesExamplePayloadsWhenAPathIsGiven
    func testWritesExamplePayloadsWhenAPathIsGiven() throws {
        guard let path = ProcessInfo.processInfo.environment["EXAMPLE_PAYLOADS_PATH"], !path.isEmpty else { return }

        enum Finish {
            case tapFirstResult, renderOnly, retrievalFailure, endBeforeRequest, superseded
        }
        struct Example {
            let name: String
            let summary: String
            let arm: String
            let state: WMFSemanticSearchInterleaveState?
            let finish: Finish
        }
        let examples = [
            Example(name: "full", summary: "Both retrievers answered and the lists were merged. The reader tapped the first result.", arm: "treatment", state: .full, finish: .tapFirstResult),
            Example(name: "lexical_only_timeout", summary: "Semantic did not answer within the timeout. The lexical list rendered at the timeout. The late response is discarded and sends nothing.", arm: "treatment", state: .lexicalOnlyTimeout, finish: .renderOnly),
            Example(name: "lexical_only_error", summary: "The semantic request failed. No error is shown to the reader.", arm: "treatment", state: .lexicalOnlyError, finish: .renderOnly),
            Example(name: "lexical_only_rate_limited", summary: "The semantic request was rate limited.", arm: "treatment", state: .lexicalOnlyRateLimited, finish: .renderOnly),
            Example(name: "lexical_only_empty", summary: "Semantic returned nothing and lexical returned results. Provisional state: US-4 does not name this case.", arm: "treatment", state: .lexicalOnlyEmpty, finish: .renderOnly),
            Example(name: "semantic_only", summary: "Lexical returned nothing and semantic returned results.", arm: "treatment", state: .semanticOnly, finish: .renderOnly),
            Example(name: "none", summary: "Both returned nothing. The existing empty state shows. The list event has no results.", arm: "treatment", state: WMFSemanticSearchInterleaveState.none, finish: .renderOnly),
            Example(name: "retrieval_failure", summary: "Both retrievers failed. The existing error state shows and no list renders.", arm: "treatment", state: nil, finish: .retrievalFailure),
            Example(name: "control", summary: "The control arm: today's lexical list, no semantic request, no merge fields and no interleave_state.", arm: "control", state: nil, finish: .tapFirstResult),
            Example(name: "ended_before_request", summary: "The reader left before the query reached the minimum length. No request, no list.", arm: "treatment", state: nil, finish: .endBeforeRequest),
            Example(name: "superseded", summary: "The reader typed again while a request was in flight. The first attempt ends as superseded and a new attempt starts.", arm: "treatment", state: .full, finish: .superseded)
        ]

        let previousInstallIDUtility = WMFDataEnvironment.current.appInstallIDUtility
        WMFDataEnvironment.current.appInstallIDUtility = { "example-install-id" }
        defer { WMFDataEnvironment.current.appInstallIDUtility = previousInstallIDUtility }

        var output: [[String: Any]] = []
        for example in examples {
            let exampleSender = RecordingEventSender()
            let exampleClient = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: exampleSender)
            let exampleInstrumentation = SearchInstrumentation(client: exampleClient)
            let arm = example.arm
            func attempt(_ id: String, _ query: String) -> WMFSemanticSearchInterleavedAttemptLog {
                WMFSemanticSearchInterleavedAttemptLog(attemptID: id, query: query, wiki: "frwiki", deviceLanguage: "fr", arm: arm)
            }
            func renderList(attemptID: String, query: String, trigger: WMFSemanticSearchInterleavedTrigger, tap: Bool) {
                let (list, results) = exampleList(arm: arm, state: example.state, attemptID: attemptID, query: query, trigger: trigger)
                exampleInstrumentation.logInterleavedListRendered(list: list, results: results)
                if tap, let first = results.first {
                    exampleInstrumentation.logInterleavedResultTap(list: list, result: first, millisecondsSinceRender: 1500)
                }
            }

            exampleInstrumentation.logInterleavedExposure(arm: arm, wiki: "frwiki")
            exampleInstrumentation.logInterleavedQueryInput(attempt("id-1", "to"))
            switch example.finish {
            case .endBeforeRequest:
                exampleInstrumentation.logInterleavedAttemptEnded(attemptID: "id-1", outcome: .endedBeforeRequest, arm: arm, wiki: "frwiki")
            case .superseded:
                exampleInstrumentation.logInterleavedQueryInput(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRetrievalEligible(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRequestIssued(attempt("id-1", "tour eiffel"), trigger: .pause)
                exampleInstrumentation.logInterleavedAttemptEnded(attemptID: "id-1", outcome: .superseded, arm: arm, wiki: "frwiki")
                exampleInstrumentation.logInterleavedQueryInput(attempt("id-2", "tour eiffel hauteur"))
                exampleInstrumentation.logInterleavedRetrievalEligible(attempt("id-2", "tour eiffel hauteur"))
                exampleInstrumentation.logInterleavedRequestIssued(attempt("id-2", "tour eiffel hauteur"), trigger: .submit)
                renderList(attemptID: "id-2", query: "tour eiffel hauteur", trigger: .submit, tap: false)
            case .retrievalFailure:
                exampleInstrumentation.logInterleavedQueryInput(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRetrievalEligible(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRequestIssued(attempt("id-1", "tour eiffel"), trigger: .pause)
                exampleInstrumentation.logInterleavedAttemptEnded(attemptID: "id-1", outcome: .retrievalFailure, arm: arm, wiki: "frwiki")
            case .renderOnly, .tapFirstResult:
                exampleInstrumentation.logInterleavedQueryInput(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRetrievalEligible(attempt("id-1", "tour eiffel"))
                exampleInstrumentation.logInterleavedRequestIssued(attempt("id-1", "tour eiffel"), trigger: .pause)
                renderList(attemptID: "id-1", query: "tour eiffel", trigger: .pause, tap: example.finish == .tapFirstResult)
            }

            let exposure = exampleSender.events.first { $0.action == "experiment_exposure" }
            output.append([
                "name": example.name,
                "summary": example.summary,
                "exposure": try exposure.map { try examplePayload($0) } ?? NSNull(),
                "events": try exampleSender.events.filter { $0.action != "experiment_exposure" }.map { try examplePayload($0) }
            ])
        }

        let document: [String: Any] = [
            "notes": [
                "Generated from fixtures with fake pages and fixed IDs, seed and latencies. Every value is an example.",
                "action_context is shown as a map. On the wire it is a JSON string whose values are all strings.",
                "Keys with no value are left out.",
                "Names and values marked provisional are not agreed yet."
            ],
            "examples": output
        ]
        let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// The list a state of the experiment renders: pages 1 to 10 are lexical and 6 to 15 are semantic, so
    /// pages 6 to 10 are in both lists. The control arm shows the lexical list as is, with no merge.
    private func exampleList(arm: String, state: WMFSemanticSearchInterleaveState?, attemptID: String, query: String, trigger: WMFSemanticSearchInterleavedTrigger) -> (WMFSemanticSearchInterleavedListLog, [WMFSemanticSearchInterleavedResultLog]) {
        let isControl = arm == "control"
        let semanticAnswered = !isControl && (state == .full || state == .lexicalOnlyEmpty || state == .semanticOnly || state == WMFSemanticSearchInterleaveState.none)
        let lexical = state == .semanticOnly || state == WMFSemanticSearchInterleaveState.none ? [] : (1...10).map { InterleavedPage(id: $0) }
        let semantic = state == .full || state == .semanticOnly ? (6...15).map { InterleavedPage(id: $0) } : []
        let merge = WMFSearchResultsInterleaver.merge(lexical: lexical, semantic: semantic, listLength: WMFSemanticSearchInterleavedConfiguration.listLength, seed: 7, pageID: { $0.id })

        let semanticMs = 280
        let waitedMs: Int
        switch state {
        case .lexicalOnlyTimeout: waitedMs = 1500
        case .lexicalOnlyError, .lexicalOnlyRateLimited: waitedMs = 150
        default: waitedMs = isControl ? 120 : semanticMs
        }
        let list = WMFSemanticSearchInterleavedListLog(
            listID: "list-\(attemptID)", attemptID: attemptID, query: query, wiki: "frwiki", deviceLanguage: "fr", arm: arm,
            mergeVersion: isControl ? nil : merge.mergeVersion, lexicalVersion: WMFLexicalListBuilder.lexicalVersion,
            seed: isControl ? nil : merge.seedLog, coinFlips: isControl ? nil : merge.coinFlipsLog,
            listLength: WMFSemanticSearchInterleavedConfiguration.listLength, interleaveState: state, trigger: trigger,
            latency: WMFSemanticSearchInterleavedLatency(lexicalMs: 120, semanticMs: semanticAnswered ? semanticMs : nil, mergeMs: 1, totalMs: waitedMs + 1),
            searchIDs: WMFSemanticSearchInterleavedIDs(prefix: "example-pre", fullText: nil, semantic: semanticAnswered ? "example-sem" : nil),
            semanticModel: semanticAnswered ? "example-model" : nil, semanticIndexVersion: semanticAnswered ? "example-index" : nil
        )
        let results = merge.resultLogs { slot in
            WMFSemanticSearchInterleavedResultDetails(pageID: slot.item.id, section: slot.item.id.isMultiple(of: 2) && slot.searchType == .semantic ? "Histoire" : nil, score: slot.searchType == .semantic ? 0.8 : nil, descriptorType: slot.searchType == .semantic ? "passage" : "lead", hasThumbnail: slot.item.id.isMultiple(of: 3), isVisible: true)
        }
        return (list, results)
    }

    private func examplePayload(_ event: Event) throws -> [String: Any] {
        var payload: [String: Any] = [:]
        payload["instrument_name"] = event.instrumentName
        payload["action"] = event.action
        payload["action_source"] = event.actionSource
        payload["action_subtype"] = event.actionSubtype
        payload["element_id"] = event.elementId
        payload["mediawiki_database"] = event.mediawikiData?.database
        if event.actionContext != nil {
            payload["action_context"] = try context(of: event)
        }
        if let experimentData = event.experimentData {
            payload["experiments"] = [
                "enrolled": experimentData.enrolled,
                "assigned": experimentData.assigned,
                "coordinator": experimentData.coordinator,
                "subject_id": experimentData.subjectId ?? NSNull()
            ] as [String: Any]
        }
        return payload
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
