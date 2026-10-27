import Testing
import WMFComponents
import WMFData
import WMFNativeLocalizations
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory(hidesDonate: { false })

    /// Only the total articles, articles visited multiple times, top topic and contributor slides have
    /// real data so far. Each always shows, in its full or its empty version, so Year in Review never
    /// opens with no slides. The test host has no stored report and no donations, so the runners-up
    /// slide does not show and the contributor slide is the "You matter" version.
    @Test
    func makesTheTotalArticlesTheArticlesVisitedMultipleTimesTheTopTopicAndTheContributorSlides() {
        let slides = factory.makeSlides(experience: .personalized, isLoggedIn: true)

        #expect(slides.count == 4)
        #expect(["frame1", "frame1-empty"].contains(slides.first?.animation?.artboardName ?? ""))
        #expect(["frame13", "frame13-empty"].contains(slides[1].animation?.artboardName ?? ""))
        #expect(["frame6", "frame6-empty"].contains(slides[2].animation?.artboardName ?? ""))
        #expect(slides.last?.animation?.artboardName == "end")
        #expect(slides.allSatisfy { $0.animation?.resourceName == "all_templates" })
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func theSlidesWriteAllOfTheirTextRuns(experience: WMFYearInReviewDataController.YiRSlidesExperience) throws {
        let slides = factory.makeSlides(experience: experience, isLoggedIn: true) + factory.collectiveSlides(config: try config())
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
            case "frame2":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"] != nil)
            case "frame6-empty":
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
        let artboards = factory.makeSlides(experience: .collective, isLoggedIn: true).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame13-empty", "frame6-empty", "end"])
    }

    /// The developer settings can force the empty version of each personalized slide.
    @Test
    func allEmptyStatesShowsOnlyEmptySlides() {
        let artboards = factory.makeSlides(experience: .personalized, isLoggedIn: true, forcesAllEmptyStates: true).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == ["frame1-empty", "frame13-empty", "frame6-empty", "end"])
    }

    /// Only the List view model has the layoutDir enum, so only the list frames set it.
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func onlyListSlidesSetTheLayoutDirection(experience: WMFYearInReviewDataController.YiRSlidesExperience) throws {
        let listFrames: Set<String> = ["frame7", "frame13", "frame13-empty"]
        let slides = factory.makeSlides(experience: experience, isLoggedIn: true) + factory.topicSlides(try topTopicsData(runnerUpIDs: ["biology", "sports"]))
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
        for slide in factory.makeSlides(experience: experience, isLoggedIn: true) {
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

    /// The design sets the number to 40 on the hours, articles and volunteer editors frames.
    @Test
    func theLongNumbersAreAtMostFortyPoints() throws {
        for slide in factory.collectiveSlides(config: try config()) {
            let fit = try #require(slide.textFits.first { $0.text.path == "data" }, "\(slide.id)")
            let artboard = slide.animation?.artboardName ?? ""
            // The global reach text uses the data text style on three lines, as in the design.
            if artboard == "frame12" {
                #expect(fit.maximumLines == 3)
                #expect(fit.fontSize.path == "dataTextFontSize")
            } else {
                #expect(fit.maximumLines == 1, "\(slide.id)")
                #expect(fit.fontSize.path == "dataNumberFontSize", "\(slide.id)")
            }
            #expect(fit.maximumFontSize == (["frame3", "frame17", "frame16"].contains(artboard) ? 40 : nil), "\(slide.id)")
        }
    }

    @Test
    func theCollectiveSlidesLimitTheirCopy() throws {
        for slide in factory.collectiveSlides(config: try config()) {
            let copy = slide.textFits.filter { $0.text.path != "data" }
            #expect(copy.map(\.fontSize.path) == ["headlineFontSize", "bodyCopyFontSize"], "\(slide.id)")
            #expect(copy.allSatisfy { $0.minimumScale == YearInReviewSlideViewModelFactory.copyMinimumScale }, "\(slide.id)")
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
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func everySlideLimitsItsCopy(experience: WMFYearInReviewDataController.YiRSlidesExperience) {
        for slide in factory.makeSlides(experience: experience, isLoggedIn: true) {
            let copy = slide.textFits.filter { $0.text.path != "data" }
            // The end frame has a glyph title in place of a headline, the same as the cover.
            let titleFontSize = slide.animation?.artboardName == "end" ? "coverGlyphsFontSize" : "headlineFontSize"
            #expect(copy.map(\.fontSize.path) == [titleFontSize, "bodyCopyFontSize"], "\(slide.id)")
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
    @Test(arguments: [WMFYearInReviewDataController.YiRSlidesExperience.personalized, .collective])
    func slideIdsAreUnique(experience: WMFYearInReviewDataController.YiRSlidesExperience) {
        let ids = factory.makeSlides(experience: experience, isLoggedIn: true).map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
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
        // The day count uses the large number style.
        #expect(slide.textFits.first { $0.text.path == "data" }?.fontSize.path == "dataNumberFontSize")
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
        // The topic name uses the data text style, not the large number style.
        let topicNameFit = slide.textFits.first { $0.text.path == "data" }
        #expect(topicNameFit?.maximumLines == 1)
        #expect(topicNameFit?.fontSize.path == "dataTextFontSize")
        #expect(topicNameFit?.lineHeight.path == "dataTextLineHeight")
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
        // A top topic with fewer than five articles read in total is not eligible.
        #expect(factory.topicSlides(try topTopicsData(readCount: 4)).map { $0.animation?.artboardName } == ["frame6-empty"])
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

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
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
        #expect(factory.makeContributorSlide(isLoggedIn: true)?.id == YearInReviewSlideViewModelFactory.nonContributorSlideID)
    }

    /// The country check decides whether the "You matter" slide shows.
    @Test
    func theYouMatterSlideFollowsTheCountryCheck() {
        let hidingFactory = YearInReviewSlideViewModelFactory(hidesDonate: { true })

        #expect(hidingFactory.makeContributorSlide(isLoggedIn: true) == nil)
        #expect(hidingFactory.makeSlides(experience: .collective, isLoggedIn: true).contains { $0.animation?.artboardName == "end" } == false)
    }
}
