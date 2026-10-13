import Testing
import WMFComponents
import WMFData
import WMFNativeLocalizations
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// Only the total articles, articles visited multiple times and top topic slides have real data so
    /// far. Each always shows, in its full or its empty version, so Year in Review never opens with no slides.
    /// The test host has no stored report, so the runners-up slide does not show.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func makesTheTotalArticlesTheArticlesVisitedMultipleTimesAndTheTopTopicSlides(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let slides = factory.makeSlides(userDataState: userDataState)

        #expect(slides.count == 3)
        #expect(["frame1", "frame1-empty"].contains(slides.first?.animation?.artboardName ?? ""))
        #expect(["frame13", "frame13-empty"].contains(slides[1].animation?.artboardName ?? ""))
        #expect(["frame6", "frame6-empty"].contains(slides.last?.animation?.artboardName ?? ""))
        #expect(slides.allSatisfy { $0.animation?.resourceName == "all_templates" })
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func theSlidesWriteAllOfTheirTextRuns(userDataState: WMFYearInReviewDataController.YiRUserDataState) throws {
        for slide in factory.makeSlides(userDataState: userDataState) {
            let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

            switch slide.animation?.artboardName {
            case "frame1-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case "frame1":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case "frame13-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyText"]?.isEmpty == false)
                #expect(slide.articleThumbnails.isEmpty)
                // The empty frame has no rows, so it does not get a row count.
                #expect(slide.numbers.isEmpty)
            case "frame13":
                #expect(byPath["bodyText"]?.isEmpty == false)
                // An unused row is written as an empty string, so all three rows are always present.
                for number in 1...3 {
                    #expect(byPath["articleTitle\(number)"] != nil, "row \(number) has no title")
                    #expect(byPath["subTitle\(number)"] != nil, "row \(number) has no subtitle")
                }
            case "frame6-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
                #expect(byPath["data"] == nil)
            default:
                Issue.record("unexpected artboard \(slide.animation?.artboardName ?? "nil")")
            }
        }
    }

    /// A low-data user sees the empty version of each slide, whatever data is stored.
    @Test
    func aLowDataUserSeesOnlyEmptySlides() {
        let artboards = factory.makeSlides(userDataState: .lowData).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame13-empty", "frame6-empty"])
    }

    /// The developer settings can force the empty version of each personalized slide for a data-rich user.
    @Test
    func allEmptyStatesShowsOnlyEmptySlides() {
        let artboards = factory.makeSlides(userDataState: .dataRich, forcesAllEmptyStates: true).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame13-empty", "frame6-empty"])
    }

    /// Each template sets `isUIWhite` for the contrast of the controls above it, so every slide must read it.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func everySlideReadsTheContrastFlag(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        for slide in factory.makeSlides(userDataState: userDataState) {
            #expect(slide.lightContentFlag?.path == "isUIWhite", "\(slide.id)")
        }
    }

    // MARK: - Total articles

    private func text(_ slide: WMFYearInReviewSlideViewModel, _ path: String) -> String? {
        slide.text.first { $0.key.path == path }?.value
    }

    @Test(arguments: [0, 2])
    func fewerThanThreeArticlesShowTheEmptyState(readCount: Int) {
        let slide = factory.totalArticlesSlide(readCount: readCount, topReadPercentage: nil, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1-empty")
        #expect(text(slide, "data") == nil)
    }

    @Test
    func aReaderInTheTopFiftyPercentSeesTheirPercentage() throws {
        let slide = factory.totalArticlesSlide(readCount: 350, topReadPercentage: 50, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1")
        #expect(text(slide, "data") == "350")
        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy.contains("50%"))
        #expect(bodyCopy.contains("335"))
        #expect(slide.localizedStrings.accessibilityLabel?.contains("350") == true)
        #expect(slide.localizedStrings.accessibilityLabel?.contains(bodyCopy) == true)
    }

    /// The large number keeps to one line. The empty slide has no number, so it fits nothing.
    @Test
    func onlyTheFullSlideFitsTheNumber() {
        let full = factory.totalArticlesSlide(readCount: 350, topReadPercentage: 50, averageReadCount: 335)
        let empty = factory.totalArticlesSlide(readCount: 0, topReadPercentage: nil, averageReadCount: 335)

        let number = full.textFits.first { $0.text.path == "data" }
        #expect(number?.maximumLines == 1)
        #expect(number?.fontSize.path == "dataNumberFontSize")
        #expect(number?.lineHeight.path == "dataNumbersLineHeight")
        #expect(empty.textFits.contains { $0.text.path == "data" } == false)
    }

    /// Long copy can push the content past the bottom of the slide, so every slide limits the
    /// headline and the body copy, and both shrink together.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func everySlideLimitsItsCopy(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        for slide in factory.makeSlides(userDataState: userDataState) {
            let copy = slide.textFits.filter { $0.text.path != "data" }
            #expect(copy.map(\.fontSize.path) == ["headlineFontSize", "bodyCopyFontSize"], "\(slide.id)")
            #expect(Set(copy.compactMap(\.group)).count == 1, "\(slide.id)")
            #expect(copy.allSatisfy { $0.minimumScale == YearInReviewSlideViewModelFactory.copyMinimumScale }, "\(slide.id)")
        }
    }

    @Test
    func theTopBucketKeepsItsFraction() throws {
        let slide = factory.totalArticlesSlide(readCount: 50000, topReadPercentage: 0.01, averageReadCount: 335)

        #expect(try #require(text(slide, "bodyCopy")).contains("0.01%"))
    }

    @Test
    func aReaderBelowTheTopFiftyPercentSeesNoPercentage() throws {
        let slide = factory.totalArticlesSlide(readCount: 3, topReadPercentage: nil, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1")
        #expect(text(slide, "data") == "3")
        #expect(try #require(text(slide, "bodyCopy")).contains("%") == false)
    }

    /// The pager keys `.scrollPosition(id:)` on the slide id. Two slides with one id stop the
    /// paging from resolving.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func slideIdsAreUnique(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let ids = factory.makeSlides(userDataState: userDataState).map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    // MARK: - Topics

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    private func topTopicsData(readCount: Int = 20, topTopicID: String? = "history", runnerUpIDs: [String] = []) throws -> WMFYearInReviewTopTopicsSlideData {
        var json: [String: Any] = [
            "readCount": readCount,
            "runnerUps": runnerUpIDs.map { ["topicID": $0, "articleCount": 3] }
        ]
        if let topTopicID {
            json["topTopic"] = [
                "topicCount": ["topicID": topTopicID, "articleCount": 23],
                "firstArticle": ["title": "Battle of Gettysburg", "projectID": "wikipedia~en"],
                "lastArticle": ["title": "Xia dynasty", "projectID": "wikipedia~en"]
            ]
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(WMFYearInReviewTopTopicsSlideData.self, from: data)
    }

    @Test
    func theTopTopicSlideShowsTheTopicTheTwoArticleTitlesAndTheTopicSentence() throws {
        let slides = factory.topicSlides(try topTopicsData())

        #expect(slides.map { $0.animation?.artboardName } == ["frame6"])
        let slide = try #require(slides.first)
        #expect(text(slide, "headline") == CommonStrings.yearInReviewTopTopicTitle)
        #expect(text(slide, "data") == WMFArticleTopic.history.displayName.localizedUppercase)
        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy.contains("Battle of Gettysburg"))
        #expect(bodyCopy.contains("Xia dynasty"))
        #expect(bodyCopy.contains("23"))
        #expect(bodyCopy.hasSuffix(CommonStrings.yearInReviewTopTopicSentenceHistory))
        // The topic name uses the data text style, not the large number style.
        let topicNameFit = slide.textFits.first { $0.text.path == "data" }
        #expect(topicNameFit?.maximumLines == 1)
        #expect(topicNameFit?.fontSize.path == "dataTextFontSize")
        #expect(topicNameFit?.lineHeight.path == "dataTextLineHeight")
    }

    @Test
    func noStoredTopTopicShowsTheEmptyState() throws {
        #expect(factory.topicSlides(nil).map { $0.animation?.artboardName } == ["frame6-empty"])
        #expect(factory.topicSlides(try topTopicsData(topTopicID: nil)).map { $0.animation?.artboardName } == ["frame6-empty"])
        // A top topic with fewer than five articles read in total is not eligible.
        #expect(factory.topicSlides(try topTopicsData(readCount: 4)).map { $0.animation?.artboardName } == ["frame6-empty"])
    }

    @Test
    func theRunnersUpShowOnlyWithTwoOrMoreTopicsAndOnlyTheirNames() throws {
        let oneRunnerUp = factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology"]))
        #expect(oneRunnerUp.map { $0.animation?.artboardName } == ["frame6"])

        let twoRunnerUps = factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology", "sports"]))
        #expect(twoRunnerUps.map { $0.animation?.artboardName } == ["frame6", "frame7"])

        let runnersUp = try #require(twoRunnerUps.last)
        #expect(text(runnersUp, "bodyText") == CommonStrings.yearInReviewRunnerUpTopicsTitle)
        #expect(text(runnersUp, "articleTitle1") == WMFArticleTopic.biology.displayName)
        #expect(text(runnersUp, "articleTitle2") == WMFArticleTopic.sports.displayName)
        // The unused row and all subtitles are written empty, so no .riv copy shows.
        #expect(text(runnersUp, "articleTitle3") == "")
        #expect((1...3).allSatisfy { text(runnersUp, "subTitle\($0)") == "" })
        // The frame shows only the rows that have a topic.
        #expect(runnersUp.numbers.first { $0.key.path == "numOfListItems" }?.value == 2)
    }

    @Test
    func eachTopicHasATopicSentence() {
        for topic in WMFArticleTopic.allCases {
            #expect(!topic.yearInReviewSentence.isEmpty, "\(topic)")
        }
        #expect(WMFArticleTopic.women.yearInReviewSentence == WMFArticleTopic.biography.yearInReviewSentence)
    }

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
    }
}
