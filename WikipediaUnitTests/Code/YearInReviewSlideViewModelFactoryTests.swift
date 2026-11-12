import Testing
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory(hidesDonate: { false })

    /// The total articles, reading streak, top topic, articles visited multiple times, saved and contributor slides always
    /// show, in their full or their empty version, so Year in Review never opens with no slides. The
    /// test host has no stored report and no donations, so the days visited, runners-up, rabbit hole
    /// and edit slides do not show and the contributor slide is the "You matter" version.
    @Test
    func makesTheTotalArticlesTheReadingStreakTheTopTopicTheArticlesVisitedMultipleTimesTheSavedAndTheContributorSlides() {
        let slides = factory.makeSlidesAndHighlights(experience: .personalized, isLoggedIn: true).slides

        #expect(slides.count == 6)
        #expect(["frame1", "frame1-empty"].contains(slides.first?.animation?.artboardName ?? ""))
        #expect(["frame4", "frame4-empty"].contains(slides[1].animation?.artboardName ?? ""))
        #expect(["frame6", "frame6-empty"].contains(slides[2].animation?.artboardName ?? ""))
        #expect(["frame13", "frame13-empty"].contains(slides[3].animation?.artboardName ?? ""))
        #expect(["frame15", "frame15-empty"].contains(slides[4].animation?.artboardName ?? ""))
        #expect(slides.last?.animation?.artboardName == "end")
        #expect(slides.allSatisfy { $0.animation?.resourceName == "all_templates" })
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func theSlidesWriteAllOfTheirTextRuns(experience: WMFYearInReviewDataController.YiRSlidesExperience) throws {
        let slides = factory.makeSlidesAndHighlights(experience: experience, isLoggedIn: true).slides + factory.collectiveSlides(config: try config())
        for slide in slides {
            let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

            switch slide.animation?.artboardName {
            case "frame1-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case "frame1":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case "frame13-empty", "frame15-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyText"]?.isEmpty == false)
                #expect(slide.articleThumbnails.isEmpty)
                // The empty frame has no rows, so it does not get a row count.
                #expect(slide.numbers.isEmpty)
            case "frame13", "frame15":
                #expect(byPath["bodyText"]?.isEmpty == false)
                // An unused row is written as an empty string, so all three rows are always present.
                for number in 1...3 {
                    #expect(byPath["articleTitle\(number)"] != nil, "row \(number) has no title")
                    #expect(byPath["subTitle\(number)"] != nil, "row \(number) has no subtitle")
                }
            case "frame2":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"] != nil)
            case "frame6-empty", "frame4-empty", "frame16-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
                #expect(byPath["data"] == nil)
            case "end":
                #expect(byPath["coverTitle"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case let artboard? where Self.collectiveArtboards.contains(artboard):
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            default:
                Issue.record("unexpected artboard \(slide.animation?.artboardName ?? "nil")")
            }
        }
    }

    /// The test host has no config, so the collective flow shows the empty version of each personalized
    /// slide, never zero slides.
    @Test
    func withoutAConfigTheCollectiveFlowShowsTheEmptySlides() {
        let artboards = factory.makeSlidesAndHighlights(experience: .collective, isLoggedIn: true).slides.map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame4-empty", "frame6-empty", "frame13-empty", "frame15-empty", "frame16-empty", "end"])
    }

    /// The developer settings can force the empty version of each personalized slide.
    @Test
    func allEmptyStatesShowsOnlyEmptySlides() {
        let artboards = factory.makeSlidesAndHighlights(experience: .personalized, isLoggedIn: true, forcesAllEmptyStates: true).slides.map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame4-empty", "frame6-empty", "frame13-empty", "frame15-empty", "frame16-empty", "end"])
    }

    /// Without a fetched edit count, for example after a failed request, no edit slide shows, so an
    /// editor is never told they made 0 edits.
    @Test
    func withoutAnEditCountNoEditSlideShows() {
        let data = YearInReviewSlideViewModelFactory.PersonalizedData(
            isLoggedIn: true,
            editCount: nil,
            editViewCount: 1_000,
            mostViewedArticles: [.init(title: "Dam", projectID: "wikipedia~en", viewsCount: 800)]
        )

        let artboards = factory.personalizedSlides(data).map { $0.animation?.artboardName ?? "nil" }

        #expect(!artboards.contains { ["frame16", "frame16-empty", "frame17", "frame18"].contains($0) })
    }

    /// A fetched edit count of 0 shows the empty edits slide.
    @Test
    func aFetchedEditCountOfZeroShowsTheEmptyEditsSlide() {
        let data = YearInReviewSlideViewModelFactory.PersonalizedData(isLoggedIn: true, editCount: 0)

        let artboards = factory.personalizedSlides(data).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards.last == "frame16-empty")
    }

    /// The most-viewed articles are not limited to the year, so a reader without edits this year gets
    /// only the empty edits slide, not the views or most-viewed articles slides.
    @Test
    func aFetchedEditCountOfZeroHidesTheViewsAndMostViewedSlides() {
        let data = YearInReviewSlideViewModelFactory.PersonalizedData(
            isLoggedIn: true,
            editCount: 0,
            editViewCount: 1_000,
            mostViewedArticles: [.init(title: "Dam", projectID: "wikipedia~en", viewsCount: 800)]
        )

        let artboards = factory.personalizedSlides(data).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards.last == "frame16-empty")
        #expect(!artboards.contains("frame17"))
        #expect(!artboards.contains("frame18"))
    }

    /// The edits slides need an account, so a logged-out reader does not get the empty edits slide.
    @Test
    func aLoggedOutReaderGetsNoEditsSlide() {
        let artboards = factory.makeSlidesAndHighlights(experience: .personalized, isLoggedIn: false, forcesAllEmptyStates: true).slides.map { $0.animation?.artboardName ?? "nil" }

        #expect(!artboards.contains("frame16-empty"))
    }

    /// The order of T438549: total articles, visits, reading streak, top topic, runners-up, biggest reading day and its
    /// articles, longest read, rabbit holes, niche interest, the articles visited multiple times, saved, then the edit slides.
    /// The longest read and rabbit hole reveals are the answers of their guess slides, not slides.
    @Test
    func thePersonalizedSlidesShowInTheOrderOfTheFlow() throws {
        let data = YearInReviewSlideViewModelFactory.PersonalizedData(
            readData: try readData(minutesRead: 5),
            daysVisited: try daysVisitedData(dayCount: 30),
            readingStreak: readingStreakData(dayCount: 11, first: (3, 4), last: (3, 14)),
            topTopics: try topTopicsData(runnerUpIDs: ["biology", "sports"]),
            biggestReadingDay: try biggestReadingDayData(articles: [("Moon", "Natural satellite"), ("Cat", nil)]),
            longestRead: try longestReadData([("Moon", "Natural satellite", 600), ("Cat", nil, 300)], longestIsOnTop: true),
            rabbitHoles: try rabbitHolesData([("Moon", "Cat", 5), ("Paris", "Europe", 3)], deepestIsOnTop: true),
            nicheCategory: WMFYearInReviewNicheCategorySlideData(categoryName: "Executed female serial killers"),
            rereadArticles: [
                .init(title: "Dam", visitCount: 3, project: nil),
                .init(title: "Gravity dam", visitCount: 2, project: nil)
            ],
            savedArticles: savedData(count: 4, articles: [("Dam", "Barrier that stops water")]),
            isLoggedIn: true,
            editCount: 12,
            editViewCount: 1_000,
            mostViewedArticles: [.init(title: "Dam", projectID: "wikipedia~en", viewsCount: 800)]
        )

        let artboards = factory.personalizedSlides(data).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1", "frame2", "frame3", "frame4", "frame6", "frame7", "frame8", "frame9", "frame10a", "frame11a", "frame12", "frame13", "frame15", "frame16", "frame17", "frame18"])
    }

    /// Only the List view model has the layoutDir enum, so only the list frames set it.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func onlyListSlidesSetTheLayoutDirection(experience: WMFYearInReviewDataController.YiRSlidesExperience) throws {
        let listFrames: Set<String> = ["frame7", "frame9", "frame13", "frame13-empty", "frame15", "frame15-empty", "frame18"]
        let slides = factory.makeSlidesAndHighlights(experience: experience, isLoggedIn: true).slides
            + factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology", "sports"]))
            + factory.biggestReadingDaySlides(try biggestReadingDayData(articles: [("Moon", nil), ("Cat", nil)]))
        for slide in slides {
            let artboard = slide.animation?.artboardName ?? ""
            if listFrames.contains(artboard) {
                #expect(slide.layoutDirection?.property.path == "layoutDir", "\(artboard)")
            } else {
                #expect(slide.layoutDirection == nil, "\(artboard)")
            }
        }
    }

    /// Each template sets `isUIWhite` for the contrast of the controls above it, so every slide must read it.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func everySlideReadsTheContrastFlag(experience: WMFYearInReviewDataController.YiRSlidesExperience) {
        for slide in factory.makeSlidesAndHighlights(experience: experience, isLoggedIn: true).slides {
            #expect(slide.lightContentFlag?.path == "isUIWhite", "\(slide.id)")
        }
    }

    // MARK: - Collective

    private static let collectiveArtboards = ["frame3", "frame4", "frame17", "frame8", "frame16", "frame5", "frame12"]

    /// The config's memberwise init is internal to WMFData, so the tests decode it like the app does.
    private func config(volunteerEditors: Int? = 250000) throws -> WMFFeatureConfigResponse.Common.YearInReview {
        var json: [String: Any] = [
            "year": 2026,
            "activeStartDate": "2026-12-02T20:00:00Z",
            "activeEndDate": "2027-02-01T00:00:00Z",
            "dataStartDate": "2026-01-01T00:00:00Z",
            "dataEndDate": "2026-12-01T00:00:00Z",
            "languages": 300,
            "articles": 65667790,
            "savedArticlesApps": 46392587,
            "viewsApps": 14085467928,
            "editsApps": 1936242,
            "editsPerMinute": 324,
            "averageArticlesReadPerYear": 335,
            "edits": 78952894,
            "editsEN": 31004338,
            "hoursReadEN": 2376881343,
            "yearsReadEN": 270000,
            "topReadEN": [String](),
            "topReadPercentages": [[String: Any]](),
            "bytesAddedEN": 3471067588,
            "hideCountryCodes": [String](),
            "hideDonateCountryCodes": [String]()
        ]
        if let volunteerEditors {
            json["editors"] = volunteerEditors
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(WMFFeatureConfigResponse.Common.YearInReview.self, from: data)
    }

    @Test
    func theCollectiveSlidesShowInTheOrderOfTheDesign() throws {
        let slides = factory.collectiveSlides(config: try config())

        #expect(slides.map { $0.animation?.artboardName } == Self.collectiveArtboards)
        #expect(slides.allSatisfy { $0.animation?.stateMachineName == "\($0.animation?.artboardName ?? "")-statemachine" })
        #expect(Set(slides.map(\.id)).count == slides.count)
        #expect(slides.allSatisfy { $0.lightContentFlag?.path == "isUIWhite" })
    }

    @Test
    func theCollectiveSlidesShowTheNumbersFromTheConfig() throws {
        let slides = factory.collectiveSlides(config: try config())
        let data = slides.map { text($0, "data") }

        #expect(data == [
            decimal(2376881343),
            CommonStrings.yearInReviewCollectiveLanguagesData(languageCount: decimal(300)),
            decimal(65667790),
            decimal(46392587),
            decimal(250000),
            decimal(78952894),
            CommonStrings.yearInReviewCollectiveGlobalReachData.localizedUppercase
        ])
        #expect(text(slides[0], "bodyCopy") == CommonStrings.yearInReviewCollectiveHoursReadSubtitle(yearCount: 270000))
        #expect(text(slides[0], "bodyCopy")?.contains(decimal(270000)) == true)
        // VoiceOver reads all of the text on the slide.
        for slide in slides {
            let label = try #require(slide.localizedStrings.accessibilityLabel)
            #expect(label.contains(try #require(text(slide, "headline"))), "\(slide.id)")
            #expect(label.contains(try #require(text(slide, "bodyCopy"))), "\(slide.id)")
        }
    }

    private func decimal(_ number: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }

    /// A config without the number of volunteer editors, such as the 2025 config, leaves that slide out.
    @Test
    func withoutVolunteerEditorsInTheConfigThatSlideDoesNotShow() throws {
        let artboards = factory.collectiveSlides(config: try config(volunteerEditors: nil)).map { $0.animation?.artboardName }

        #expect(artboards == Self.collectiveArtboards.filter { $0 != "frame16" })
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
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func slideIdsAreUnique(experience: WMFYearInReviewDataController.YiRSlidesExperience) {
        let ids = factory.makeSlidesAndHighlights(experience: experience, isLoggedIn: true).slides.map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    // MARK: - Minutes read

    /// `format` is `nil` for data from builds before the minutes read slide.
    private func readData(readCount: Int = 10, minutesRead: Int, format: Int? = WMFYearInReviewReadData.currentMinutesReadFormat) throws -> WMFYearInReviewReadData {
        var json: [String: Any] = ["readCount": readCount, "minutesRead": minutesRead]
        json["minutesReadFormat"] = format
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(WMFYearInReviewReadData.self, from: data)
    }

    @Test
    func theMinutesReadSlideShowsTheMinutesAndTheComparison() throws {
        let slide = try #require(factory.minutesReadSlide(try readData(minutesRead: 924)))

        #expect(text(slide, "headline") == CommonStrings.yearInReviewMinutesReadTitle)
        #expect(text(slide, "data") == "924")
        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy == "\(CommonStrings.yearInReviewMinutesReadComparisonNightSleep) \(CommonStrings.yearInReviewMinutesReadSubtitle)")
        let accessibilityLabel = try #require(slide.localizedStrings.accessibilityLabel)
        #expect(accessibilityLabel.contains("924"))
        #expect(accessibilityLabel.contains(bodyCopy))
    }

    @Test
    func theMinutesReadSlideNamesTheDaysForAVeryLongReadingTime() throws {
        let slide = try #require(factory.minutesReadSlide(try readData(minutesRead: 2880)))

        #expect(text(slide, "bodyCopy")?.hasPrefix(CommonStrings.yearInReviewMinutesReadComparisonDays(dayCount: 2)) == true)
    }

    @Test(arguments: [0, 300_001])
    func theMinutesReadSlideDoesNotShowWithoutEnoughOrWithTooManyMinutes(minutesRead: Int) throws {
        #expect(factory.minutesReadSlide(try readData(minutesRead: minutesRead)) == nil)
    }

    @Test
    func theMinutesReadSlideDoesNotShowWithoutStoredData() {
        #expect(factory.minutesReadSlide(nil) == nil)
    }

    @Test
    func theMinutesReadSlideDoesNotShowOutdatedData() throws {
        #expect(factory.minutesReadSlide(try readData(minutesRead: 924, format: nil)) == nil, "old reports counted all page views")
        #expect(factory.minutesReadSlide(try readData(minutesRead: 924, format: WMFYearInReviewReadData.currentMinutesReadFormat - 1)) == nil)
    }

    // MARK: - Days visited

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    private func daysVisitedData(dayCount: Int, peakMonth: Int? = nil, peakMonthDayCount: Int = 20) throws -> WMFYearInReviewDaysVisitedSlideData {
        var json: [String: Any] = ["dayCount": dayCount]
        if let peakMonth {
            json["peakMonth"] = ["month": peakMonth, "dayCount": peakMonthDayCount]
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(WMFYearInReviewDaysVisitedSlideData.self, from: data)
    }

    @Test
    func theDaysVisitedSlideShowsTheDayCountAndThePeakMonth() throws {
        let slide = try #require(factory.daysVisitedSlide(try daysVisitedData(dayCount: 55, peakMonth: 12)))

        #expect(slide.animation?.artboardName == "frame2")
        #expect(slide.animation?.stateMachineName == "frame2-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewDaysVisitedTitle)
        #expect(text(slide, "data") == "55")
        let december = Calendar.current.standaloneMonthSymbols[11]
        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy == CommonStrings.yearInReviewDaysVisitedSubtitle(month: december, dayCount: 20))
        #expect(bodyCopy.contains(december))
        #expect(bodyCopy.contains("20"))
        // VoiceOver reads all of the text on the slide.
        let accessibilityLabel = try #require(slide.localizedStrings.accessibilityLabel)
        #expect(accessibilityLabel.contains(CommonStrings.yearInReviewDaysVisitedTitle))
        #expect(accessibilityLabel.contains("55"))
        #expect(accessibilityLabel.contains(bodyCopy))
    }

    /// Without a peak month, the body copy is written empty, so the copy inside the .riv does not show.
    @Test
    func withoutAPeakMonthTheDaysVisitedSlideShowsOnlyTheDayCount() throws {
        let slide = try #require(factory.daysVisitedSlide(try daysVisitedData(dayCount: 2)))

        #expect(text(slide, "data") == "2")
        #expect(text(slide, "bodyCopy") == "")
        #expect(slide.localizedStrings.accessibilityLabel == "\(CommonStrings.yearInReviewDaysVisitedTitle) 2.")
    }

    /// The slide has no empty version, so it does not show with fewer than two days or without stored data.
    @Test
    func theDaysVisitedSlideNeedsTwoDays() throws {
        #expect(factory.daysVisitedSlide(nil) == nil)
        #expect(factory.daysVisitedSlide(try daysVisitedData(dayCount: 0)) == nil)
        #expect(factory.daysVisitedSlide(try daysVisitedData(dayCount: 1, peakMonth: 3, peakMonthDayCount: 1)) == nil)
    }

    // MARK: - Saved articles

    private func savedData(count: Int, articles: [(title: String, description: String?)], projectID: String? = "wikipedia~en") -> SavedArticleSlideData {
        SavedArticleSlideData(
            savedArticlesCount: count,
            articles: articles.map { .init(title: $0.title, pageTitle: $0.title, articleDescription: $0.description, projectID: projectID) }
        )
    }

    @Test
    func theSavedSlideShowsTheCountAndUpToThreeArticlesWithTheirDescriptions() {
        let slide = factory.savedArticlesSlide(savedData(count: 26, articles: [
            ("Dam", "Barrier that stops water"),
            ("Moon", nil),
            ("Cat", "Small domesticated carnivorous mammal"),
            ("Dog", "Domesticated canine")
        ]))

        #expect(slide.animation?.artboardName == "frame15")
        #expect(slide.animation?.stateMachineName == "frame15-statemachine")
        #expect(text(slide, "bodyText") == "\(CommonStrings.yearInReviewSavedArticlesTitle) \(decimal(26))")
        #expect(text(slide, "headline") == nil)
        #expect(text(slide, "articleTitle1") == "Dam")
        #expect(text(slide, "subTitle1") == "Barrier that stops water")
        #expect(text(slide, "articleTitle2") == "Moon")
        // Without a description, the row writes an empty subtitle so the copy inside the .riv does not show.
        #expect(text(slide, "subTitle2") == "")
        #expect(text(slide, "articleTitle3") == "Cat")
        #expect(slide.numbers.first(where: { $0.key.path == "numOfListItems" })?.value == 3)
        #expect(slide.articleThumbnails.count == 3)
        #expect(slide.articleThumbnails.first(where: { $0.key.path == "icon1" })?.value.title == "Dam")
    }

    @Test
    func oneSavedArticleShowsTheFullSlideWithOneRow() {
        let slide = factory.savedArticlesSlide(savedData(count: 1, articles: [("Dam", nil)]))

        #expect(slide.animation?.artboardName == "frame15")
        #expect(slide.numbers.first(where: { $0.key.path == "numOfListItems" })?.value == 1)
        #expect(text(slide, "articleTitle2") == "")
    }

    @Test
    func withoutAWikiTheSavedSlideKeepsThePlaceholderImage() {
        let slide = factory.savedArticlesSlide(savedData(count: 1, articles: [("Dam", nil)], projectID: nil))

        #expect(slide.articleThumbnails.isEmpty)
    }

    @Test
    func noSavedArticlesShowTheEmptyState() throws {
        // An older build stored only the count and the titles.
        let legacy = try JSONDecoder().decode(SavedArticleSlideData.self, from: Data(#"{"savedArticlesCount":5,"articleTitles":["Dam"]}"#.utf8))
        for slideData in [nil, savedData(count: 0, articles: []), legacy] {
            let slide = factory.savedArticlesSlide(slideData)

            #expect(slide.animation?.artboardName == "frame15-empty")
            #expect(slide.animation?.stateMachineName == "frame15-empty-statemachine")
            #expect(text(slide, "headline") == CommonStrings.yearInReviewSavedArticlesEmptyTitle)
            #expect(text(slide, "bodyText") == CommonStrings.yearInReviewSavedArticlesEmptySubtitle)
        }
    }

    // MARK: - Reading streak

    private func readingStreakData(dayCount: Int, first: (month: Int, day: Int), last: (month: Int, day: Int)) -> WMFYearInReviewReadingStreakSlideData {
        WMFYearInReviewReadingStreakSlideData(
            dayCount: dayCount,
            firstDay: .init(year: 2026, month: first.month, day: first.day),
            lastDay: .init(year: 2026, month: last.month, day: last.day)
        )
    }

    private var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test
    func theReadingStreakSlideShowsTheDayCountAndTheDateRange() {
        let slide = factory.readingStreakSlide(readingStreakData(dayCount: 11, first: (3, 4), last: (3, 14)), calendar: gregorianUTC, locale: Locale(identifier: "en_US"))

        #expect(slide.animation?.artboardName == "frame4")
        #expect(slide.animation?.stateMachineName == "frame4-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewReadingStreakTitle)
        #expect(text(slide, "data") == decimal(11))
        let bodyCopy = text(slide, "bodyCopy") ?? ""
        #expect(bodyCopy.contains("March 4"))
        #expect(bodyCopy.contains("14"))
        // The year is left out of the date range.
        #expect(!bodyCopy.contains("2026"))
        #expect(slide.localizedStrings.accessibilityLabel?.contains(bodyCopy) == true)
    }

    @Test
    func theReadingStreakDateRangeFollowsTheLocale() {
        let slide = factory.readingStreakSlide(readingStreakData(dayCount: 4, first: (3, 30), last: (4, 2)), calendar: gregorianUTC, locale: Locale(identifier: "de_DE"))

        let bodyCopy = text(slide, "bodyCopy") ?? ""
        #expect(bodyCopy.contains("30. März"))
        #expect(bodyCopy.contains("2. Apr"))
    }

    @Test
    func theReadingStreakSlideNeedsThreeConsecutiveDays() {
        for slideData in [nil, readingStreakData(dayCount: 1, first: (3, 4), last: (3, 4)), readingStreakData(dayCount: 2, first: (3, 4), last: (3, 5)), WMFYearInReviewReadingStreakSlideData(dayCount: 0, firstDay: nil, lastDay: nil)] {
            let slide = factory.readingStreakSlide(slideData)

            #expect(slide.animation?.artboardName == "frame4-empty")
            #expect(slide.animation?.stateMachineName == "frame4-empty-statemachine")
            #expect(text(slide, "headline") == CommonStrings.yearInReviewReadingStreakEmptyTitle)
            #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewReadingStreakEmptySubtitle)
            #expect(text(slide, "data") == nil)
        }

        #expect(factory.readingStreakSlide(readingStreakData(dayCount: 3, first: (3, 4), last: (3, 6))).animation?.artboardName == "frame4")
    }

    // MARK: - Biggest reading day

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    private func biggestReadingDayData(month: Int = 3, day: Int = 7, minuteCount: Int = 43, articles: [(title: String, description: String?)], articleCount: Int? = nil) throws -> WMFYearInReviewBiggestReadingDaySlideData {
        let articleJSON: [[String: Any]] = articles.map { article in
            var json: [String: Any] = ["title": article.title, "projectID": "wikipedia~en"]
            json["description"] = article.description
            return json
        }
        let json: [String: Any] = ["year": 2026, "month": month, "day": day, "minuteCount": minuteCount, "articleCount": articleCount ?? articles.count, "articles": articleJSON]
        return try JSONDecoder().decode(WMFYearInReviewBiggestReadingDaySlideData.self, from: try JSONSerialization.data(withJSONObject: json))
    }

    @Test
    func theBiggestReadingDaySlideShowsTheDateWithoutTheYearAndTheMinutes() throws {
        let slides = factory.biggestReadingDaySlides(try biggestReadingDayData(month: 3, day: 7, minuteCount: 43, articles: [("Moon", nil)]))
        let slide = try #require(slides.first)

        #expect(slides.count == 1, "one article is not enough for the articles slide")
        #expect(slide.id == "biggestReadingDay")
        #expect(slide.loggingID == "biggest_reading_day")
        #expect(slide.animation?.artboardName == "frame8")
        #expect(slide.animation?.stateMachineName == "frame8-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewBiggestReadingDayTitle)
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 7)))
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        let day = formatter.string(from: date)
        #expect(text(slide, "data") == day.localizedUppercase)
        #expect(text(slide, "data")?.contains("2026") == false)
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewBiggestReadingDaySubtitle(minuteCount: 43))
        #expect(slide.localizedStrings.accessibilityLabel == "\(CommonStrings.yearInReviewBiggestReadingDayTitle) \(day). \(CommonStrings.yearInReviewBiggestReadingDaySubtitle(minuteCount: 43))")
    }

    @Test
    func theArticlesSlideShowsUpToThreeArticlesWithTheirDescriptions() throws {
        let slideData = try biggestReadingDayData(articles: [("Moon", "Natural satellite"), ("Cat", nil), ("Paris", "Capital of France")], articleCount: 7)
        let slides = factory.biggestReadingDaySlides(slideData)
        let slide = try #require(slides.last)

        #expect(slides.count == 2)
        #expect(slide.id == "biggestReadingDayArticles")
        #expect(slide.loggingID == "biggest_reading_day_articles")
        #expect(slide.animation?.artboardName == "frame9")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewArticlesReadTitle)
        #expect(text(slide, "articleTitle1") == "Moon")
        #expect(text(slide, "subTitle1") == "Natural satellite")
        #expect(text(slide, "subTitle2") == "", "an article without a description clears the copy inside the .riv")
        #expect(text(slide, "articleTitle3") == "Paris")
        #expect(slide.numbers[WMFRiveNumber(path: "numOfListItems")] == 3)
        #expect(Set(slide.articleThumbnails.keys.map(\.path)) == ["icon1", "icon2", "icon3"])
        #expect(slide.localizedStrings.accessibilityLabel == "\(CommonStrings.yearInReviewArticlesReadTitle) Moon, Natural satellite. Cat. Paris, Capital of France.")
    }

    /// Neither slide has an empty version.
    @Test
    func theBiggestReadingDaySlidesNeedTwoMinutesAndAtMostTheMaximum() throws {
        #expect(factory.biggestReadingDaySlides(nil).isEmpty)
        #expect(factory.biggestReadingDaySlides(try biggestReadingDayData(minuteCount: 1, articles: [("Moon", nil), ("Cat", nil)])).isEmpty)
        #expect(factory.biggestReadingDaySlides(try biggestReadingDayData(minuteCount: 300_001, articles: [("Moon", nil), ("Cat", nil)])).isEmpty)
        #expect(factory.biggestReadingDaySlides(try biggestReadingDayData(minuteCount: 300_000, articles: [("Moon", nil), ("Cat", nil)])).count == 2)
    }

    // MARK: - Niche interest

    @Test
    func theNicheInterestSlideShowsTheCategoryName() throws {
        let categoryName = "Executed female serial killers"
        let slide = try #require(factory.nicheInterestSlide(WMFYearInReviewNicheCategorySlideData(categoryName: categoryName)))

        #expect(slide.id == "nicheInterest")
        #expect(slide.animation?.artboardName == "frame12")
        #expect(slide.animation?.stateMachineName == "frame12-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewNicheInterestTitle)
        #expect(text(slide, "data") == categoryName.localizedUppercase)
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewNicheInterestSubtitle)
        // VoiceOver reads the category name as written, not in capitals.
        #expect(slide.localizedStrings.accessibilityLabel == "\(CommonStrings.yearInReviewNicheInterestTitle) \(categoryName). \(CommonStrings.yearInReviewNicheInterestSubtitle)")
    }

    /// The slide has no empty version, so it does not show without a category name.
    @Test(arguments: [nil, "", "   "] as [String?])
    func theNicheInterestSlideNeedsACategoryName(categoryName: String?) {
        #expect(factory.nicheInterestSlide(WMFYearInReviewNicheCategorySlideData(categoryName: categoryName)) == nil)
    }

    /// The slide does not show when the report does not have its data.
    @Test
    func theNicheInterestSlideNeedsStoredData() {
        #expect(factory.nicheInterestSlide(nil) == nil)
    }

    // MARK: - Topics

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    /// - Parameter illustrations: Image data keyed by Commons file name. JSON stores `Data` as Base64.
    private func topTopicsData(readCount: Int = 20, topTopicID: String? = "history", runnerUpIDs: [String] = [], illustrations: [String: Data]? = nil) throws -> WMFYearInReviewTopTopicsSlideData {
        var json: [String: Any] = [
            "readCount": readCount,
            // Each runner-up has fewer articles than the one before it: 12, 11, 10.
            "runnerUps": runnerUpIDs.enumerated().map { ["topicID": $0.element, "articleCount": 12 - $0.offset] }
        ]
        if let illustrations {
            json["illustrations"] = illustrations.mapValues { $0.base64EncodedString() }
        }
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
    }

    /// The downloaded illustrations fill topicIcon on frame6 and the row icons on frame7.
    @Test
    func theTopicSlidesShowTheDownloadedIllustrations() throws {
        let history = Data("history".utf8)
        let regional = Data("regional".utf8)
        let slideData = try topTopicsData(
            runnerUpIDs: ["europe", "asia", "biology"],
            illustrations: ["17 History.png": history, "33 - 39 Regional.png": regional]
        )

        let slides = factory.topicSlides(slideData)
        let topTopic = try #require(slides.first)
        let runnersUp = try #require(slides.last)

        #expect(topTopic.images.first { $0.key.path == "topicIcon" }?.value == history)
        let icons = Dictionary(uniqueKeysWithValues: runnersUp.images.map { ($0.key.path, $0.value) })
        #expect(icons["icon1"] == regional)
        #expect(icons["icon2"] == regional)
        // Biology did not download, so its row keeps the placeholder in the .riv.
        #expect(icons["icon3"] == nil)
    }

    @Test
    func withoutIllustrationsTheTopicSlidesSetNoImages() throws {
        let slides = factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology", "sports"]))
        #expect(slides.allSatisfy { $0.images.isEmpty })
    }

    @Test
    func noStoredTopTopicShowsTheEmptyState() throws {
        #expect(factory.topicSlides(nil).map { $0.animation?.artboardName } == ["frame6-empty"])
        #expect(factory.topicSlides(try topTopicsData(topTopicID: nil)).map { $0.animation?.artboardName } == ["frame6-empty"])
    }

    /// The total number of articles read does not matter. Only the top topic decides, the same as on Android.
    @Test
    func aTopTopicShowsTheFullSlideWithFewArticlesRead() throws {
        #expect(factory.topicSlides(try topTopicsData(readCount: 3)).map { $0.animation?.artboardName } == ["frame6"])
    }

    @Test
    func theRunnersUpShowOnlyWithTwoOrMoreTopicsAndTheirArticleCounts() throws {
        let oneRunnerUp = factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology"]))
        #expect(oneRunnerUp.map { $0.animation?.artboardName } == ["frame6"])

        let twoRunnerUps = factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology", "sports"]))
        #expect(twoRunnerUps.map { $0.animation?.artboardName } == ["frame6", "frame7"])

        let runnersUp = try #require(twoRunnerUps.last)
        #expect(text(runnersUp, "bodyText") == CommonStrings.yearInReviewRunnerUpTopicsTitle)
        #expect(text(runnersUp, "articleTitle1") == WMFArticleTopic.biology.displayName)
        #expect(text(runnersUp, "articleTitle2") == WMFArticleTopic.sports.displayName)
        #expect(text(runnersUp, "subTitle1") == String.localizedStringWithFormat(CommonStrings.articleCountFormat, 12))
        #expect(text(runnersUp, "subTitle2") == String.localizedStringWithFormat(CommonStrings.articleCountFormat, 11))
        #expect(text(runnersUp, "subTitle1")?.contains("12") == true)
        // The unused row is written empty, so no .riv copy shows.
        #expect(text(runnersUp, "articleTitle3") == "")
        #expect(text(runnersUp, "subTitle3") == "")
        #expect(runnersUp.localizedStrings.accessibilityLabel?.contains(String.localizedStringWithFormat(CommonStrings.articleCountFormat, 11)) == true)
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

    // MARK: - Edits

    @Test
    func theEditsSlideShowsTheEditCount() throws {
        let slide = factory.editsSlide(editCount: 357)

        #expect(slide.id == "edits")
        #expect(slide.animation?.artboardName == "frame16")
        #expect(slide.animation?.stateMachineName == "frame16-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewEditsTitle)
        #expect(text(slide, "data") == "357")
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewEditsSubtitle)
        let accessibilityLabel = try #require(slide.localizedStrings.accessibilityLabel)
        #expect(accessibilityLabel.contains("357"))
    }

    /// One edit is enough for the full slide.
    @Test
    func oneEditShowsTheFullEditsSlide() {
        #expect(factory.editsSlide(editCount: 1).animation?.artboardName == "frame16")
    }

    @Test
    func noEditsShowsTheEmptyEditsSlide() {
        let slide = factory.editsSlide(editCount: 0)

        #expect(slide.id == "editsEmpty")
        #expect(slide.animation?.artboardName == "frame16-empty")
        #expect(slide.animation?.stateMachineName == "frame16-empty-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewEditsEmptyTitle)
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewEditsEmptySubtitle)
        #expect(text(slide, "data") == nil)
    }

    // MARK: - Edit views

    @Test
    func theEditViewsSlideShowsTheViewCount() throws {
        let slide = try #require(factory.editViewsSlide(viewCount: 26))

        #expect(slide.id == "editViews")
        #expect(slide.animation?.artboardName == "frame17")
        #expect(slide.animation?.stateMachineName == "frame17-statemachine")
        #expect(text(slide, "headline") == CommonStrings.yearInReviewEditViewsTitle)
        #expect(text(slide, "data") == "26")
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewEditViewsSubtitle)
    }

    /// The slide needs more than 25 views. It has no empty version.
    @Test(arguments: [nil, 0, 25] as [Int?])
    func theEditViewsSlideNeedsMoreThan25Views(viewCount: Int?) {
        #expect(factory.editViewsSlide(viewCount: viewCount) == nil)
    }

    // MARK: - Most-viewed articles

    @Test
    func theMostViewedArticlesSlideListsUpToThreeArticlesWithTheirViews() throws {
        let articles = [("IOS", 109), ("Test5", 22), ("Test 2", 9), ("Test 3", 1)].map {
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: $0.0, projectID: "wikipedia~en", viewsCount: $0.1)
        }
        let slide = try #require(factory.mostViewedArticlesSlide(articles))

        #expect(slide.id == "mostViewedArticles")
        #expect(slide.animation?.artboardName == "frame18")
        #expect(slide.animation?.stateMachineName == "frame18-statemachine")
        #expect(text(slide, "bodyText") == CommonStrings.yearInReviewMostViewedEditedArticlesTitle)
        #expect(text(slide, "articleTitle1") == "IOS")
        #expect(text(slide, "subTitle1") == CommonStrings.yearInReviewMostViewedEditedArticlesViewCount(109))
        #expect(text(slide, "articleTitle3") == "Test 2")
        #expect(slide.text.keys.contains { $0.path == "articleTitle4" } == false)
        #expect(slide.articleThumbnails.count == 3)
    }

    /// The slide has no empty version.
    @Test
    func theMostViewedArticlesSlideDoesNotShowWithoutArticles() {
        #expect(factory.mostViewedArticlesSlide([]) == nil)
    }

    // MARK: - Contributor

    @Test(arguments: [(true, true), (true, false), (false, true)])
    func aContributorSeesTheThankYouSlide(isEditor: Bool, isDonor: Bool) throws {
        let slide = try #require(factory.contributorSlide(isEditor: isEditor, isDonor: isDonor, isLoggedIn: true, hidesDonate: false))

        #expect(slide.id == "contributor")
        #expect(slide.animation?.artboardName == "end")
        #expect(slide.animation?.stateMachineName == "end-statemachine")
        #expect(text(slide, "coverTitle") == CommonStrings.yearInReviewThankYouTitle.localizedUppercase)
        let expectedBody: String
        switch (isEditor, isDonor) {
        case (true, true): expectedBody = CommonStrings.yearInReviewThankYouEditorAndDonorSubtitle
        case (true, false): expectedBody = CommonStrings.yearInReviewThankYouEditorSubtitle
        default: expectedBody = CommonStrings.yearInReviewThankYouDonorSubtitle
        }
        #expect(text(slide, "bodyCopy") == expectedBody)
        #expect(slide.showsDonateButton)
        #expect(slide.showsPrimaryDonateButton == false)
    }

    /// The donate button in the toolbar hides where donations are not accepted, but the slide still shows.
    @Test
    func aContributorSeesTheThankYouSlideWhereDonationsAreNotAccepted() {
        let slide = factory.contributorSlide(isEditor: true, isDonor: false, isLoggedIn: true, hidesDonate: true)

        #expect(slide?.id == "contributor")
    }

    @Test
    func aLoggedInNonContributorSeesTheYouMatterSlide() throws {
        let slide = try #require(factory.contributorSlide(isEditor: false, isDonor: false, isLoggedIn: true, hidesDonate: false))

        #expect(slide.id == "nonContributor")
        #expect(slide.animation?.artboardName == "end")
        #expect(text(slide, "coverTitle") == CommonStrings.yearInReviewYouMatterTitle.localizedUppercase)
        #expect(text(slide, "bodyCopy") == CommonStrings.yearInReviewYouMatterSubtitle)
        #expect(slide.showsPrimaryDonateButton)
    }

    @Test
    func aLoggedOutNonContributorIsAskedToLogIn() throws {
        let slide = try #require(factory.contributorSlide(isEditor: false, isDonor: false, isLoggedIn: false, hidesDonate: false))

        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy.hasPrefix(CommonStrings.yearInReviewYouMatterSubtitle))
        #expect(bodyCopy.hasSuffix(CommonStrings.yearInReviewYouMatterLogInSubtitle))
        #expect(slide.localizedStrings.accessibilityLabel?.contains(CommonStrings.yearInReviewYouMatterLogInSubtitle) == true)
    }

    /// The donor recognition requires log in, so a logged-out contributor sees "You matter" and is
    /// asked to log in, also with a donation on the device.
    @Test(arguments: [(true, true), (true, false), (false, true)])
    func aLoggedOutContributorSeesTheYouMatterSlide(isEditor: Bool, isDonor: Bool) throws {
        let slide = try #require(factory.contributorSlide(isEditor: isEditor, isDonor: isDonor, isLoggedIn: false, hidesDonate: false))

        #expect(slide.id == YearInReviewSlideViewModelFactory.nonContributorSlideID)
        #expect(text(slide, "coverTitle") == CommonStrings.yearInReviewYouMatterTitle.localizedUppercase)
        #expect(text(slide, "bodyCopy")?.hasSuffix(CommonStrings.yearInReviewYouMatterLogInSubtitle) == true)
        #expect(slide.showsPrimaryDonateButton)
    }

    /// Where donations are not accepted, a logged-out contributor sees no contributor slide, the
    /// same as a non-contributor.
    @Test
    func aLoggedOutContributorSeesNoSlideWhereDonationsAreNotAccepted() {
        #expect(factory.contributorSlide(isEditor: true, isDonor: true, isLoggedIn: false, hidesDonate: true) == nil)
    }

    @Test
    func theYouMatterSlideDoesNotShowWhereDonationsAreNotAccepted() {
        #expect(factory.contributorSlide(isEditor: false, isDonor: false, isLoggedIn: true, hidesDonate: true) == nil)
    }

    /// The test host has no donations and no report, so the refreshed slide is still "You matter".
    @Test
    func theContributorSlideCanBeRebuiltOnItsOwn() {
        #expect(factory.makeContributorSlide(experience: .personalized, isLoggedIn: true)?.id == YearInReviewSlideViewModelFactory.nonContributorSlideID)
    }

    /// Only the personalized slides end with "Thank you". The collective slides always end with
    /// "You matter", the same as on Android.
    @Test
    func aContributorSeesThankYouOnlyInThePersonalizedSlides() {
        let editorFactory = YearInReviewSlideViewModelFactory(hidesDonate: { false }, contributorStatus: { .init(isEditor: true, isDonor: true) })

        #expect(editorFactory.makeContributorSlide(experience: .personalized, isLoggedIn: true)?.id == YearInReviewSlideViewModelFactory.contributorSlideID)
        #expect(editorFactory.makeContributorSlide(experience: .collective, isLoggedIn: true)?.id == YearInReviewSlideViewModelFactory.nonContributorSlideID)
        #expect(editorFactory.makeSlidesAndHighlights(experience: .collective, isLoggedIn: true).slides.last?.id == YearInReviewSlideViewModelFactory.nonContributorSlideID)
    }

    /// The country check decides whether the "You matter" slide shows.
    @Test
    func theYouMatterSlideFollowsTheCountryCheck() {
        let hidingFactory = YearInReviewSlideViewModelFactory(hidesDonate: { true })

        #expect(hidingFactory.makeContributorSlide(experience: .collective, isLoggedIn: true) == nil)
        #expect(hidingFactory.makeSlidesAndHighlights(experience: .collective, isLoggedIn: true).slides.contains { $0.animation?.artboardName == "end" } == false)
    }

    // MARK: - Longest read

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    /// - Parameter articles: The title, the description and the seconds of each article, longest first.
    private func longestReadData(_ articles: [(String, String?, Int)], longestIsOnTop: Bool) throws -> WMFYearInReviewLongestReadSlideData {
        let json: [String: Any] = [
            "articles": articles.map { title, description, seconds in
                var article: [String: Any] = ["title": title, "projectID": "wikipedia~en", "seconds": seconds]
                article["description"] = description
                return article
            },
            "longestIsOnTop": longestIsOnTop
        ]
        return try JSONDecoder().decode(WMFYearInReviewLongestReadSlideData.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test(arguments: [true, false])
    func theLongestReadSlideShowsTheGuessThenTheLongestReadArticleInPlace(longestIsOnTop: Bool) throws {
        let slideData = try longestReadData([("Moon", "Natural satellite", 754), ("Cat", nil, 300)], longestIsOnTop: longestIsOnTop)

        let slides = factory.longestReadSlides(slideData)

        #expect(slides.count == 1, "the guess and the reveal take one position in the pager")
        let guess = try #require(slides.first)
        #expect(guess.id == "longestReadGuess")
        #expect(guess.loggingID == "longest_read_guess")
        #expect(guess.animation?.artboardName == "frame10a")
        #expect(guess.animation?.stateMachineName == "frame10a-statemachine")
        #expect(text(guess, "headline") == CommonStrings.yearInReviewMostTimeArticleTitle)
        let (top, bottom) = longestIsOnTop ? (("Moon", "Natural satellite"), ("Cat", "")) : (("Cat", ""), ("Moon", "Natural satellite"))
        #expect(text(guess, "articleTitleTop") == top.0)
        #expect(text(guess, "subTitleTop") == top.1)
        #expect(text(guess, "articleTitleBot") == bottom.0)
        #expect(text(guess, "subTitleBot") == bottom.1)
        #expect(guess.articleThumbnails.first { $0.key.path == "thumbnailTop" }?.value.title == top.0)
        #expect(guess.articleThumbnails.first { $0.key.path == "thumbnailBot" }?.value.title == bottom.0)
        #expect(guess.answerTrigger?.path == "frameComplete", "after the reader taps a card and the cards exit, the reveal replaces the guess")
        #expect(guess.sharePoseTime != nil, "the share image shows the guess at rest, the same as the rabbit hole guess")

        let reveal = try #require(guess.answer)
        #expect(reveal.id == "longestReadReveal")
        #expect(reveal.loggingID == "longest_read_reveal")
        #expect(reveal.animation?.artboardName == "frame10b")
        #expect(text(reveal, "headline") == CommonStrings.yearInReviewMostTimeArticleSubtitle(minuteCount: 12))
        #expect(text(reveal, "resultTitle") == "Moon")
        #expect(text(reveal, "resultSubTitle") == "Natural satellite")
        #expect(reveal.articleThumbnails.first { $0.key.path == "resultThumbnail" }?.value.title == "Moon")
        #expect(reveal.answer == nil)
        #expect(reveal.answerTrigger == nil)
        #expect(reveal.sharePoseTime == nil, "the reveal uses the usual share pose, the same as the rabbit hole reveal")
    }

    @Test
    func theLongestReadSlidesReadTheContrastFlag() throws {
        let guess = try #require(factory.longestReadSlides(try longestReadData([("Moon", nil, 600), ("Cat", nil, 300)], longestIsOnTop: true)).first)
        #expect(guess.lightContentFlag?.path == "isUIWhite")
        #expect(guess.answer?.lightContentFlag?.path == "isUIWhite")
    }

    @Test
    func withoutAClearWinnerTheLongestReadSlideDoesNotShow() throws {
        #expect(factory.longestReadSlides(try longestReadData([("Moon", nil, 300), ("Cat", nil, 300)], longestIsOnTop: true)).isEmpty)
        #expect(factory.longestReadSlides(try longestReadData([("Moon", nil, 300)], longestIsOnTop: true)).isEmpty)
        #expect(factory.longestReadSlides(nil).isEmpty)
    }

    // MARK: - Rabbit holes

    /// The payload's memberwise init is internal to WMFData, so the tests decode it like the app does.
    /// - Parameter rabbitHoles: The first and the last title and the article count of each rabbit hole, deepest first.
    private func rabbitHolesData(_ rabbitHoles: [(String, String, Int)], deepestIsOnTop: Bool) throws -> WMFYearInReviewRabbitHolesSlideData {
        let json: [String: Any] = [
            "rabbitHoles": rabbitHoles.map { first, last, count in
                [
                    "firstArticle": ["title": first, "projectID": "wikipedia~en"],
                    "lastArticle": ["title": last, "projectID": "wikipedia~en"],
                    "articleCount": count
                ]
            },
            "deepestIsOnTop": deepestIsOnTop
        ]
        return try JSONDecoder().decode(WMFYearInReviewRabbitHolesSlideData.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test(arguments: [true, false])
    func theRabbitHoleSlideShowsTheGuessThenTheDeepestRabbitHoleInPlace(deepestIsOnTop: Bool) throws {
        let slideData = try rabbitHolesData([("Moon", "Cat", 5), ("Paris", "Europe", 3)], deepestIsOnTop: deepestIsOnTop)

        let slides = factory.rabbitHoleSlides(slideData)

        #expect(slides.count == 1, "the guess and the reveal take one position in the pager")
        let guess = try #require(slides.first)
        #expect(guess.animation?.artboardName == "frame11a")
        #expect(text(guess, "headline") == CommonStrings.yearInReviewRabbitHoleTitle)
        let (top, bottom) = deepestIsOnTop ? (("Moon", "Cat"), ("Paris", "Europe")) : (("Paris", "Europe"), ("Moon", "Cat"))
        #expect(text(guess, "articleTitleTopT") == top.0)
        #expect(text(guess, "articleTitleTopB") == top.1)
        #expect(text(guess, "articleTitleBotT") == bottom.0)
        #expect(text(guess, "articleTitleBotB") == bottom.1)
        #expect(guess.answerTrigger?.path == "frameComplete", "after the reader taps a card and the cards exit, the reveal replaces the guess")

        let reveal = try #require(guess.answer)
        #expect(reveal.animation?.artboardName == "frame11b")
        #expect(text(reveal, "headline") == CommonStrings.yearInReviewRabbitHoleRevealTitle(articleCount: 5))
        #expect(text(reveal, "bodyText") == CommonStrings.yearInReviewRabbitHoleRevealSubtitle)
        #expect(text(reveal, "resultTitleTop") == "Moon")
        #expect(text(reveal, "resultTitleBot") == "Cat")
        #expect(reveal.answer == nil)
        #expect(reveal.answerTrigger == nil)
    }

    /// Each article thumbnail has a flag that hides the placeholder image while the thumbnail is missing.
    @Test
    func eachRabbitHoleThumbnailHasAMissingImageFlag() throws {
        let slides = factory.rabbitHoleSlides(try rabbitHolesData([("Moon", "Cat", 5), ("Paris", "Europe", 3)], deepestIsOnTop: true))

        let guess = try #require(slides.first)
        #expect(Set(guess.articleThumbnails.keys.map(\.path)) == ["thumbnailTopT", "thumbnailTopB", "thumbnailBotT", "thumbnailBotB"])
        #expect(guess.missingImageFlags.first { $0.key.path == "thumbnailBotB" }?.value.path == "noImgBotB")
        let reveal = try #require(guess.answer)
        #expect(Set(reveal.missingImageFlags.map { "\($0.key.path):\($0.value.path)" }) == ["resultThumbnailTop:resultNoImgT", "resultThumbnailBot:resultNoImgB"])
        #expect(reveal.articleThumbnails.first { $0.key.path == "resultThumbnailBot" }?.value.title == "Cat")
    }

    @Test
    func withOneRabbitHoleTheRabbitHoleSlidesDoNotShow() throws {
        #expect(factory.rabbitHoleSlides(try rabbitHolesData([("Moon", "Cat", 5)], deepestIsOnTop: true)).isEmpty)
        #expect(factory.rabbitHoleSlides(nil).isEmpty)
    }

    // MARK: - Highlights

    @Test
    func theHighlightsHaveEveryStatThatTheReaderHas() throws {
        let highlights = factory.highlights(
            readData: try readData(readCount: 120, minutesRead: 900),
            rereadArticles: [
                .init(title: "Moon", visitCount: 9, project: nil),
                .init(title: "Cat", visitCount: 7, project: nil),
                .init(title: "Paris", visitCount: 5, project: nil),
                .init(title: "Europe", visitCount: 3, project: nil)
            ],
            rabbitHoles: try rabbitHolesData([("Moon", "Cat", 5), ("Paris", "Europe", 3)], deepestIsOnTop: false),
            nicheCategory: WMFYearInReviewNicheCategorySlideData(categoryName: "Executed female serial killers")
        )

        #expect(highlights.articlesRead == 120)
        #expect(highlights.minutesRead == 900)
        #expect(highlights.rotation == ["Moon", "Cat", "Paris"], "at most three, most visited first")
        #expect(highlights.rabbitHole == .init(firstTitle: "Moon", lastTitle: "Cat"), "the deepest, wherever the guess slide put it")
        #expect(highlights.nicheCategory == "Executed female serial killers")
        #expect(highlights.highlightCount == 5)
        #expect(highlights.isShareable)
        #expect(highlights.localizedStrings.createdWith == CommonStrings.yearInReviewHighlightsCreatedWith)
        #expect(highlights.localizedStrings.rotationRank(2) == CommonStrings.yearInReviewHighlightsRank(2))
        #expect(CommonStrings.yearInReviewHighlightsRank(2) == "(2)")
    }

    /// A highlight shows only when its slide showed its full version, except the article count.
    @Test
    func theHighlightsLeaveOutWhatTheSlidesLeftOut() throws {
        let highlights = factory.highlights(
            readData: try readData(readCount: 0, minutesRead: 4),
            rereadArticles: [.init(title: "Moon", visitCount: 9, project: nil)],
            rabbitHoles: try rabbitHolesData([("Moon", "Cat", 5)], deepestIsOnTop: true),
            nicheCategory: WMFYearInReviewNicheCategorySlideData(categoryName: " ")
        )

        #expect(highlights.articlesRead == nil)
        #expect(highlights.minutesRead == 4)
        #expect(highlights.rotation.isEmpty)
        #expect(highlights.rabbitHole == nil)
        #expect(highlights.nicheCategory == nil, "a blank category name does not show the niche interest slide")
        #expect(highlights.highlightCount == 1)
        #expect(highlights.isShareable == false, "with fewer than two highlights, Share highlights does not show")
    }

    /// Product decision: the article count shows from one article, also when the total articles slide was empty.
    @Test
    func theHighlightsShowTheArticleCountFromOneArticle() throws {
        let highlights = factory.highlights(
            readData: try readData(readCount: 1, minutesRead: 4),
            rereadArticles: [],
            rabbitHoles: nil,
            nicheCategory: nil
        )

        #expect(WMFYearInReviewReadData.minimumReadCount > 1, "the total articles slide shows its empty version")
        #expect(highlights.articlesRead == 1)
        #expect(highlights.highlightCount == 2)
        #expect(highlights.isShareable)
    }

    /// The minutes follow the minutes read slide, so the image never shows minutes that the slide hid.
    @Test(arguments: [
        (minutesRead: 924, format: nil as Int?),
        (minutesRead: 924, format: WMFYearInReviewReadData.currentMinutesReadFormat - 1),
        (minutesRead: WMFYearInReviewReadData.maximumMinutesRead + 1, format: WMFYearInReviewReadData.currentMinutesReadFormat)
    ])
    func theHighlightsLeaveOutTheMinutesThatTheSlideHid(minutesRead: Int, format: Int?) throws {
        let readData = try readData(readCount: 20, minutesRead: minutesRead, format: format)

        #expect(factory.minutesReadSlide(readData) == nil)
        #expect(factory.highlights(readData: readData, rereadArticles: [], rabbitHoles: nil, nicheCategory: nil).minutesRead == nil)
    }

    /// Only the built-in text activities get the share text. Every other activity, such as Instagram,
    /// TikTok or Save to Files, gets only the image.
    @Test
    func onlyBuiltInTextActivitiesGetTheShareText() {
        #expect(YearInReviewShareTextItem.takesText(.message))
        #expect(YearInReviewShareTextItem.takesText(.mail))
        #expect(YearInReviewShareTextItem.takesText(.copyToPasteboard))
        #expect(YearInReviewShareTextItem.takesText(.saveToCameraRoll) == false)
        #expect(YearInReviewShareTextItem.takesText(UIActivity.ActivityType("com.apple.CloudDocsUI.AddToiCloudDrive")) == false)
        #expect(YearInReviewShareTextItem.takesText(UIActivity.ActivityType("com.burbn.instagram.shareextension")) == false)
        #expect(YearInReviewShareTextItem.takesText(nil) == false)
    }

    @Test
    func theCollectiveFlowHasNoHighlights() {
        #expect(factory.makeSlidesAndHighlights(experience: .collective, isLoggedIn: true).highlights == nil)
        #expect(factory.makeSlidesAndHighlights(experience: .personalized, isLoggedIn: true, forcesAllEmptyStates: true).highlights == nil)
    }

    /// The instrumentation plan names each page, and the donate campaign ID is made from that name.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func theSlidesLogThePageNamesOfTheInstrumentationPlan(experience: WMFYearInReviewDataController.YiRSlidesExperience) throws {
        let planPages: Set<String> = [
            "total_articles", "total_articles_empty", "visits", "minutes_read", "reading_streak", "reading_streak_empty", "top_topic", "top_topic_empty", "other_top_topics",
            "rabbit_hole_guess", "rabbit_hole_reveal", "revisited_articles", "revisited_articles_empty",
            "saved_articles", "saved_articles_empty",
            "collective_hours_read", "collective_languages", "collective_articles", "collective_saved_articles",
            "collective_volunteer_editors", "collective_edits", "collective_global_reach", "thank_you", "you_matter"
        ]
        // TODO: The 2026 instrumentation plan does not name the edit slides yet, so they log their raw
        // ids. Remove this filter when their page names are added to `loggingIDs` (see the TODO there).
        let slidesWithoutPlanPages: Set<String> = ["edits", "editsEmpty", "editViews", "mostViewedArticles"]
        let slides = (factory.makeSlidesAndHighlights(experience: experience, isLoggedIn: true).slides + factory.collectiveSlides(config: try config()))
            .filter { !slidesWithoutPlanPages.contains($0.id) }
        for slide in slides {
            #expect(planPages.contains(slide.loggingID), "\(slide.id) logs \(slide.loggingID)")
        }
        #expect(YearInReviewSlideViewModelFactory.loggingID(forSlideID: YearInReviewSlideViewModelFactory.contributorSlideID) == "thank_you")
        #expect(YearInReviewSlideViewModelFactory.loggingID(forSlideID: "rabbitHoleReveal") == "rabbit_hole_reveal")
        #expect(YearInReviewSlideViewModelFactory.loggingID(forSlideID: "minutesRead") == "minutes_read")
    }
}
