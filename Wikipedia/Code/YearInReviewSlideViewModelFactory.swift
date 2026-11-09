import CocoaLumberjackSwift
import Foundation
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Makes the content that the Year in Review view model is built from.
struct YearInReviewSlideViewModelFactory {

    /// True where donations are not accepted. Tests pass a fixed value.
    private let hidesDonate: () -> Bool

    /// Tests pass a fixed value. `nil` reads the stored edits and the donations on the device.
    private let contributorStatus: (() -> ContributorStatus)?

    /// Without the data controller, the country check cannot run. Then the donate slide hides, so
    /// it never shows where donations are not accepted.
    init(hidesDonate: @escaping () -> Bool = { (try? WMFYearInReviewDataController())?.shouldHideDonateButton() ?? true }, contributorStatus: (() -> ContributorStatus)? = nil) {
        self.hidesDonate = hidesDonate
        self.contributorStatus = contributorStatus
    }

    /// The `page` names of the 2026 instrumentation plan. The donate campaign ID is also made from them.
    private static let loggingIDs: [String: String] = [
        "totalArticles": "total_articles",
        "totalArticlesEmpty": "total_articles_empty",
        "daysVisited": "visits",
        "readingStreak": "reading_streak",
        "readingStreakEmpty": "reading_streak_empty",
        "topTopic": "top_topic",
        "topTopicEmpty": "top_topic_empty",
        "runnerUpTopics": "other_top_topics",
        "rabbitHoleGuess": "rabbit_hole_guess",
        "rabbitHoleReveal": "rabbit_hole_reveal",
        "rereadArticles": "revisited_articles",
        "rereadArticlesEmpty": "revisited_articles_empty",
        "collectiveHoursRead": "collective_hours_read",
        "collectiveLanguages": "collective_languages",
        "collectiveArticles": "collective_articles",
        "collectiveSavedArticles": "collective_saved_articles",
        "collectiveEditors": "collective_volunteer_editors",
        "collectiveEdits": "collective_edits",
        "collectiveGlobalReach": "collective_global_reach",
        contributorSlideID: "thank_you",
        nonContributorSlideID: "you_matter"
    ]

    static func loggingID(forSlideID id: String) -> String {
        loggingIDs[id] ?? id
    }

    /// Shared with the announcement's more menu.
    static var aboutInsightsButtonTitle: String {
        WMFLocalizedString("year-in-review-2026-about-insights", value: "About your insights", comment: "Title of the Year in Review more menu item that opens the Frequently Asked Questions page.")
    }

    func makeLocalizedStrings() -> WMFYearInReviewViewModel.LocalizedStrings {
        WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: CommonStrings.plainWikipediaName,
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: CommonStrings.moreButton,
            shareButtonTitle: CommonStrings.shortShareTitle,
            shareHighlightsButtonTitle: CommonStrings.yearInReviewOutroShareButtonTitle,
            donateButtonTitle: CommonStrings.donateTitle,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            aboutInsightsButtonTitle: Self.aboutInsightsButtonTitle,
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle,
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    /// Only the total articles, days visited, reading streak, articles visited multiple times, topic, rabbit hole, niche interest and contributor slides have real data so far.
    /// The personalized slides show the user's data, but a slide without enough data shows its empty version.
    /// The days visited, rabbit hole and niche interest slides have no empty version, so they do not show without enough data.
    /// The collective slides show data for all readers. Every flow ends with the contributor slide,
    /// but only the personalized flow can end with "Thank you", the same as on Android.
    ///
    /// Also returns what "Share highlights" on the end screen shares. The slides and the highlights come
    /// from one read of the stored report, so the image cannot show other data than the slides. The
    /// highlights are `nil` in the collective flow, and when the developer settings force the empty
    /// states, because then the reader saw no highlights.
    /// - Parameters:
    ///   - isLoggedIn: A logged-out non-contributor is asked to log in to see their contributions.
    ///   - forcesAllEmptyStates: shows the empty version of each personalized slide. Only the developer settings use it.
    func makeSlidesAndHighlights(experience: WMFYearInReviewDataController.YiRSlidesExperience, isLoggedIn: Bool, forcesAllEmptyStates: Bool = false) -> (slides: [WMFYearInReviewSlideViewModel], highlights: WMFYearInReviewHighlights?) {
        // Each stored value is a fetch and a decode of the report, on the main thread, so read them once.
        let personalizedData = experience == .personalized && !forcesAllEmptyStates ? storedPersonalizedData() : nil
        let contributorSlides = makeContributorSlide(experience: experience, isLoggedIn: isLoggedIn).map { [$0] } ?? []
        let slides = experienceSlides(experience, personalizedData: personalizedData) + contributorSlides
        return (slides, personalizedData.map(highlights(from:)))
    }

    /// The contributor slide from the stored edits and the donations on the device. Also used to
    /// refresh the slide after a donation. The collective flow always ends with "You matter".
    func makeContributorSlide(experience: WMFYearInReviewDataController.YiRSlidesExperience, isLoggedIn: Bool) -> WMFYearInReviewSlideViewModel? {
        let contributor = experience == .personalized
            ? (contributorStatus?() ?? storedContributorStatus())
            : ContributorStatus(isEditor: false, isDonor: false)
        return contributorSlide(
            isEditor: contributor.isEditor,
            isDonor: contributor.isDonor,
            isLoggedIn: isLoggedIn,
            hidesDonate: hidesDonate()
        )
    }

    /// - Parameter personalizedData: `nil` in the personalized flow shows the empty version of each slide.
    private func experienceSlides(_ experience: WMFYearInReviewDataController.YiRSlidesExperience, personalizedData: PersonalizedData?) -> [WMFYearInReviewSlideViewModel] {
        switch experience {
        case .collective:
            // Without a config, Year in Review does not open, but never show zero slides.
            guard let config = try? WMFYearInReviewDataController().config else {
                return personalizedEmptySlides()
            }
            return collectiveSlides(config: config)
        case .personalized:
            guard let personalizedData else {
                return personalizedEmptySlides()
            }
            return personalizedSlides(personalizedData)
        }
    }

    /// Reads the stored data of each personalized slide once.
    /// No stored data means no qualifying articles, so the slides show their empty states, never zero slides.
    private func storedPersonalizedData() -> PersonalizedData {
        let config = try? WMFYearInReviewDataController().config
        let readData = storedReadData()
        return PersonalizedData(
            readData: readData,
            topReadPercentage: config?.topReadPercentage(forReadCount: readData?.readCount ?? 0),
            averageReadCount: config?.averageArticlesReadPerYear,
            daysVisited: storedDaysVisited(),
            readingStreak: storedReadingStreak(),
            topTopics: storedTopTopics(),
            rabbitHoles: storedRabbitHoles(),
            nicheCategory: storedNicheCategory(),
            rereadArticles: storedRereadArticles() ?? []
        )
    }

    /// The stored data of the personalized slides.
    struct PersonalizedData {
        /// For the total articles slide and the highlights. `nil` shows the empty total articles slide.
        var readData: WMFYearInReviewReadData?
        /// No stored data means no qualifying articles.
        var readCount: Int { readData?.readCount ?? 0 }
        var topReadPercentage: Double?
        var averageReadCount: Int?
        var daysVisited: WMFYearInReviewDaysVisitedSlideData?
        /// `nil` shows the empty reading streak slide.
        var readingStreak: WMFYearInReviewReadingStreakSlideData?
        var topTopics: WMFYearInReviewTopTopicsSlideData?
        var rabbitHoles: WMFYearInReviewRabbitHolesSlideData?
        var nicheCategory: WMFYearInReviewNicheCategorySlideData?
        var rereadArticles: [RereadArticle] = []
    }

    /// The personalized slides in the order of T438549. These slides are not built yet, so they are
    /// not in the flow: time spent, reading pattern, biggest reading day,
    /// longest read, geography, saved, the edit slides and the end screen.
    func personalizedSlides(_ data: PersonalizedData) -> [WMFYearInReviewSlideViewModel] {
        var slides = [
            totalArticlesSlide(readCount: data.readCount, topReadPercentage: data.topReadPercentage, averageReadCount: data.averageReadCount)
        ]
        if let daysVisited = daysVisitedSlide(data.daysVisited) {
            slides.append(daysVisited)
        }
        slides.append(readingStreakSlide(data.readingStreak))
        slides += topicSlides(data.topTopics)
        slides += rabbitHoleSlides(data.rabbitHoles)
        if let nicheInterest = nicheInterestSlide(data.nicheCategory) {
            slides.append(nicheInterest)
        }
        slides.append(rereadArticlesSlide(data.rereadArticles))
        return slides
    }

    /// In the same order as `personalizedSlides(_:)`.
    private func personalizedEmptySlides() -> [WMFYearInReviewSlideViewModel] {
        [totalArticlesEmptySlide(), readingStreakEmptySlide(), topTopicEmptySlide(), rereadArticlesEmptySlide()]
    }

    // MARK: - Stored slide data

    /// Reads the data of one slide from the report that the app fills in the background.
    /// Returns `nil` when the report does not have the slide, or when the data does not decode.
    /// - Parameters:
    ///   - id: The slide to read.
    ///   - type: The type that the slide data decodes into.
    ///   - logName: The slide name that the error log shows.
    private func storedSlideData<SlideData: Decodable>(_ id: WMFYearInReviewPersonalizedSlideID, as type: SlideData.Type, logName: String) -> SlideData? {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == id })?.data else {
                return nil
            }
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DDLogError("Error reading the Year in Review \(logName): \(error)")
            return nil
        }
    }

    // MARK: - Total articles

    /// The number of unique articles read and the minutes read, from the report the app fills in
    /// the background. `nil` when the report does not have this slide yet.
    private func storedReadData() -> WMFYearInReviewReadData? {
        storedSlideData(.readCount, as: WMFYearInReviewReadData.self, logName: "total articles")
    }

    /// Shows the empty version unless the reader read at least `WMFYearInReviewReadData.minimumReadCount` articles.
    /// - Parameters:
    ///   - topReadPercentage: The "top X%" of readers globally, for example `50` or `0.01`. `nil` when the reader is below the 50th percentile.
    ///   - averageReadCount: The number of articles the average person reads in a year.
    func totalArticlesSlide(readCount: Int, topReadPercentage: Double?, averageReadCount: Int?) -> WMFYearInReviewSlideViewModel {
        guard let readCount = SlideEligibility.readCount(readCount) else {
            return totalArticlesEmptySlide()
        }

        let headline = CommonStrings.yearInReviewTotalArticlesTitle
        let count = NumberFormatter.localizedString(from: NSNumber(value: readCount), number: .decimal)
        let bodyText: String
        if let topReadPercentage, let averageReadCount {
            bodyText = CommonStrings.yearInReviewTotalArticlesTopPercentSubtitle(percent: percentString(topReadPercentage), averageReadCount: averageReadCount)
        } else {
            bodyText = CommonStrings.yearInReviewTotalArticlesSubtitle
        }
        return dataSlide(
            id: "totalArticles",
            artboard: "frame1",
            stateMachine: "frame1-statemachine",
            headline: headline,
            data: count,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(count). \(bodyText)"
        )
    }

    private func totalArticlesEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewTotalArticlesEmptyTitle
        let bodyText = CommonStrings.yearInReviewTotalArticlesEmptySubtitle
        return dataSlide(
            id: "totalArticlesEmpty",
            artboard: "frame1-empty",
            stateMachine: "frame1-empty-statemachine",
            headline: headline,
            data: nil,
            bodyText: bodyText,
            accessibilityLabel: "\(headline). \(bodyText)"
        )
    }

    /// `percentage` is out of 100, for example `0.01` becomes "0.01%".
    private func percentString(_ percentage: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: percentage / 100)) ?? "\(percentage)%"
    }

    // MARK: - Days visited

    /// The reading days, from the report the app fills in the background. `nil` when the report
    /// does not have this slide yet.
    private func storedDaysVisited() -> WMFYearInReviewDaysVisitedSlideData? {
        storedSlideData(.daysVisited, as: WMFYearInReviewDaysVisitedSlideData.self, logName: "days visited")
    }

    /// `nil` unless the reader read on at least `WMFYearInReviewDaysVisitedSlideData.minimumDayCount`
    /// days. The slide has no empty version. Without a peak month, the slide shows only the number.
    func daysVisitedSlide(_ slideData: WMFYearInReviewDaysVisitedSlideData?) -> WMFYearInReviewSlideViewModel? {
        guard let slideData, slideData.isEligible else {
            return nil
        }

        let headline = CommonStrings.yearInReviewDaysVisitedTitle
        let count = NumberFormatter.localizedString(from: NSNumber(value: slideData.dayCount), number: .decimal)
        // Write an empty body copy without a peak month, so that the copy inside the .riv does not show.
        var bodyText = ""
        if let peakMonth = slideData.peakMonth, let monthName = monthName(peakMonth.month) {
            bodyText = CommonStrings.yearInReviewDaysVisitedSubtitle(month: monthName, dayCount: peakMonth.dayCount)
        }
        return dataSlide(
            id: "daysVisited",
            artboard: "frame2",
            stateMachine: "frame2-statemachine",
            headline: headline,
            data: count,
            bodyText: bodyText,
            accessibilityLabel: bodyText.isEmpty ? "\(headline) \(count)." : "\(headline) \(count). \(bodyText)"
        )
    }

    /// The standalone name of the month, for example "December". `month` is from 1 to 12.
    private func monthName(_ month: Int) -> String? {
        let monthSymbols = Calendar.current.standaloneMonthSymbols
        guard monthSymbols.indices.contains(month - 1) else {
            return nil
        }
        return monthSymbols[month - 1]
    }

    // MARK: - Reading streak

    /// The longest reading streak, from the report the app fills in the background. `nil` when the
    /// report does not have this slide yet.
    private func storedReadingStreak() -> WMFYearInReviewReadingStreakSlideData? {
        storedSlideData(.readingStreak, as: WMFYearInReviewReadingStreakSlideData.self, logName: "reading streak")
    }

    /// Shows the number of days in the longest streak and its dates. Shows the empty version unless
    /// the reader read on at least `WMFYearInReviewReadingStreakSlideData.minimumDayCount` consecutive days.
    /// - Parameter calendar: The calendar of the streak days and of the date range. Tests pass a fixed one.
    func readingStreakSlide(_ slideData: WMFYearInReviewReadingStreakSlideData?, calendar: Calendar = .current, locale: Locale = .current) -> WMFYearInReviewSlideViewModel {
        guard let slideData,
              slideData.isEligible,
              let firstDay = slideData.firstDay?.date(in: calendar),
              let lastDay = slideData.lastDay?.date(in: calendar) else {
            return readingStreakEmptySlide()
        }

        let headline = CommonStrings.yearInReviewReadingStreakTitle
        let count = decimalString(slideData.dayCount)
        let bodyText = CommonStrings.yearInReviewReadingStreakSubtitle(dateRange: dateRangeString(from: firstDay, to: lastDay, calendar: calendar, locale: locale))
        return dataSlide(
            id: "readingStreak",
            artboard: "frame4",
            stateMachine: "frame4-statemachine",
            headline: headline,
            data: count,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(count). \(bodyText)"
        )
    }

    private func readingStreakEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewReadingStreakEmptyTitle
        let bodyText = CommonStrings.yearInReviewReadingStreakEmptySubtitle
        return dataSlide(
            id: "readingStreakEmpty",
            artboard: "frame4-empty",
            stateMachine: "frame4-empty-statemachine",
            headline: headline,
            data: nil,
            bodyText: bodyText,
            accessibilityLabel: "\(headline). \(bodyText)"
        )
    }

    /// The month and day of both dates in the format of the locale, for example "March 4 – 14" or
    /// "March 30 – April 2". The year is left out, because the streak is always in the data period.
    private func dateRangeString(from startDate: Date, to endDate: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateIntervalFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateTemplate = "MMMMd"
        return formatter.string(from: startDate, to: endDate)
    }

    // MARK: - Articles visited multiple times

    struct RereadArticle {
        let title: String
        let visitCount: Int
        /// The wiki of the article, for its thumbnail. `nil` shows the placeholder in the .riv.
        let project: WMFProject?
    }

    /// The articles visited multiple times, from the report the app fills in the background.
    /// `nil` when the report does not have this slide yet.
    private func storedRereadArticles() -> [RereadArticle]? {
        guard let slideData = storedSlideData(.topArticles, as: WMFYearInReviewTopArticlesSlideData.self, logName: "articles visited multiple times") else {
            return nil
        }
        guard slideData.isEligible else {
            return []
        }
        return slideData.articles.map { RereadArticle(title: $0.title, visitCount: $0.visitCount, project: $0.project) }
    }

    /// Shows the empty version unless at least two articles were visited multiple times.
    func rereadArticlesSlide(_ articles: [RereadArticle]) -> WMFYearInReviewSlideViewModel {
        guard let articles = SlideEligibility.rereadArticles(articles) else {
            return rereadArticlesEmptySlide()
        }

        let bodyText = CommonStrings.yearInReviewRereadArticlesTitle
        let shownArticles = Array(articles.prefix(3))
        let items = shownArticles.map { article in
            ListItem(title: article.title, subtitle: CommonStrings.yearInReviewRereadArticlesVisitCount(article.visitCount))
        }
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        for (index, article) in shownArticles.enumerated() {
            guard let project = article.project else { continue }
            thumbnails[ListImagePath.icon(index + 1)] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: project, title: article.title)
        }
        return listSlide(
            id: "rereadArticles",
            artboard: "frame13",
            stateMachine: "frame13-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            articleThumbnails: thumbnails,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    private func rereadArticlesEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewRereadArticlesEmptyTitle
        let bodyText = CommonStrings.yearInReviewRereadArticlesEmptySubtitle
        return listSlide(
            id: "rereadArticlesEmpty",
            artboard: "frame13-empty",
            stateMachine: "frame13-empty-statemachine",
            headline: headline,
            bodyText: bodyText,
            items: [],
            accessibilityLabel: "\(headline). \(bodyText)"
        )
    }

    // MARK: - Niche interest

    /// The category that the reader read in a niche way, from the report the app fills in the
    /// background. `nil` when the report does not have this slide yet.
    private func storedNicheCategory() -> WMFYearInReviewNicheCategorySlideData? {
        storedSlideData(.mostReadCategories, as: WMFYearInReviewNicheCategorySlideData.self, logName: "niche interest")
    }

    /// Shows one category name. The data controller picks the category when it builds the report,
    /// so the same category shows each time. `nil` when the reader has no category to show.
    /// The slide has no empty version.
    func nicheInterestSlide(_ slideData: WMFYearInReviewNicheCategorySlideData?) -> WMFYearInReviewSlideViewModel? {
        guard let categoryName = SlideEligibility.nicheCategoryName(slideData) else {
            return nil
        }

        let headline = CommonStrings.yearInReviewNicheInterestTitle
        let bodyText = CommonStrings.yearInReviewNicheInterestSubtitle

        // `dataSlide` shows the data in capitals, so the category name is passed as written.
        return dataSlide(
            id: "nicheInterest",
            artboard: "frame12",
            stateMachine: "frame12-statemachine",
            headline: headline,
            data: categoryName,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(categoryName). \(bodyText)"
        )
    }

    // MARK: - Topics

    /// The topic slides, from the report the app fills in the background. `nil` when the report
    /// does not have these slides yet.
    private func storedTopTopics() -> WMFYearInReviewTopTopicsSlideData? {
        storedSlideData(.topTopics, as: WMFYearInReviewTopTopicsSlideData.self, logName: "top topics")
    }

    /// The top topic slide, then the runners-up slide if there are enough runners-up. Shows the
    /// empty version of the top topic slide if the reader does not have a top topic.
    func topicSlides(_ slideData: WMFYearInReviewTopTopicsSlideData?) -> [WMFYearInReviewSlideViewModel] {
        guard let slideData,
              slideData.isEligible,
              let topTopic = slideData.topTopic,
              let topic = topTopic.topicCount.topic else {
            return [topTopicEmptySlide()]
        }

        var slides = [topTopicSlide(topic: topic, topTopic: topTopic, illustration: slideData.illustration(for: topic))]
        if slideData.showsRunnerUps {
            let runnerUps = slideData.runnerUps.compactMap { topicCount in
                topicCount.topic.map { RunnerUpTopic(topic: $0, articleCount: topicCount.articleCount, illustration: slideData.illustration(for: $0)) }
            }
            slides.append(runnerUpTopicsSlide(runnerUps))
        }
        return slides
    }

    /// The image property of the topic illustration on frame6.
    private static let topicIcon = WMFRiveImage(path: "topicIcon")

    /// - Parameter illustration: The image data of the topic illustration. `nil` shows the sample illustration in the .riv.
    private func topTopicSlide(topic: WMFArticleTopic, topTopic: WMFYearInReviewTopTopicsSlideData.TopTopic, illustration: Data?) -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewTopTopicTitle
        let topicName = topic.displayName
        let subtitle = CommonStrings.yearInReviewTopTopicSubtitle(
            firstArticleTitle: topTopic.firstArticle.title,
            lastArticleTitle: topTopic.lastArticle.title,
            articleCount: topTopic.topicCount.articleCount
        )
        let bodyText = "\(subtitle) \(topic.yearInReviewSentence)"

        // `dataSlide` shows the data in capitals, so the topic name is passed as written.
        return dataSlide(
            id: "topTopic",
            artboard: "frame6",
            stateMachine: "frame6-statemachine",
            headline: headline,
            data: topicName,
            bodyText: bodyText,
            images: illustration.map { [Self.topicIcon: $0] } ?? [:],
            accessibilityLabel: "\(headline) \(topicName). \(bodyText)"
        )
    }

    private func topTopicEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewTopTopicEmptyTitle
        let bodyText = CommonStrings.yearInReviewTopTopicEmptySubtitle
        return dataSlide(
            id: "topTopicEmpty",
            artboard: "frame6-empty",
            stateMachine: "frame6-empty-statemachine",
            headline: headline,
            data: nil,
            bodyText: bodyText,
            accessibilityLabel: "\(headline). \(bodyText)"
        )
    }

    /// One row on the runners-up slide.
    private struct RunnerUpTopic {
        let topic: WMFArticleTopic
        let articleCount: Int
        /// The image data of the topic illustration. `nil` keeps the placeholder in the .riv.
        let illustration: Data?
    }

    /// Each row shows the topic name, the number of articles and the topic illustration.
    private func runnerUpTopicsSlide(_ runnerUps: [RunnerUpTopic]) -> WMFYearInReviewSlideViewModel {
        let bodyText = CommonStrings.yearInReviewRunnerUpTopicsTitle
        let shownRunnerUps = Array(runnerUps.prefix(WMFYearInReviewTopTopicsSlideData.maximumRunnerUpCount))
        let items = shownRunnerUps.map { runnerUp in
            ListItem(title: runnerUp.topic.displayName, subtitle: String.localizedStringWithFormat(CommonStrings.articleCountFormat, runnerUp.articleCount))
        }
        var images: [WMFRiveImage: Data] = [:]
        for (index, runnerUp) in shownRunnerUps.enumerated() {
            if let illustration = runnerUp.illustration {
                images[ListImagePath.icon(index + 1)] = illustration
            }
        }
        return listSlide(
            id: "runnerUpTopics",
            artboard: "frame7",
            stateMachine: "frame7-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            images: images,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    // MARK: - Rabbit holes

    /// The rabbit holes, from the report the app fills in the background. `nil` when the report
    /// does not have these slides yet.
    private func storedRabbitHoles() -> WMFYearInReviewRabbitHolesSlideData? {
        storedSlideData(.rabbitHoles, as: WMFYearInReviewRabbitHolesSlideData.self, logName: "rabbit holes")
    }

    /// Properties on the `Interaction2` view model in the templates file. On the guess frame, the
    /// top card and the bottom card each show the first article (T) and the last article (B) of
    /// a rabbit hole. The reveal frame shows the deepest rabbit hole with the result properties.
    private enum RabbitHolePath {
        static let headline = WMFRiveText(path: "headline")
        static let bodyText = WMFRiveText(path: "bodyText")
        /// The guess frame fires it after the reader taps a card and the exit animation ends.
        static let frameComplete = WMFRiveTrigger(path: "frameComplete")
        /// The guess frame rests from 2.0 to 2.7 seconds, after the cards come in. From about 2.8
        /// seconds it moves the bottom card again and again until the reader taps, so at 7 seconds the
        /// share image can show the card in mid-move. The reveal frame stops at 1.25 seconds, so it
        /// keeps the usual time.
        static let guessSharePoseTime: TimeInterval = 2.4

        struct Article {
            let title: WMFRiveText
            let thumbnail: WMFRiveImage
            let noImage: WMFRiveBool
        }

        static let topCardFirst = Article(title: WMFRiveText(path: "articleTitleTopT"), thumbnail: WMFRiveImage(path: "thumbnailTopT"), noImage: WMFRiveBool(path: "noImgTopT"))
        static let topCardLast = Article(title: WMFRiveText(path: "articleTitleTopB"), thumbnail: WMFRiveImage(path: "thumbnailTopB"), noImage: WMFRiveBool(path: "noImgTopB"))
        static let bottomCardFirst = Article(title: WMFRiveText(path: "articleTitleBotT"), thumbnail: WMFRiveImage(path: "thumbnailBotT"), noImage: WMFRiveBool(path: "noImgBotT"))
        static let bottomCardLast = Article(title: WMFRiveText(path: "articleTitleBotB"), thumbnail: WMFRiveImage(path: "thumbnailBotB"), noImage: WMFRiveBool(path: "noImgBotB"))
        static let resultFirst = Article(title: WMFRiveText(path: "resultTitleTop"), thumbnail: WMFRiveImage(path: "resultThumbnailTop"), noImage: WMFRiveBool(path: "resultNoImgT"))
        static let resultLast = Article(title: WMFRiveText(path: "resultTitleBot"), thumbnail: WMFRiveImage(path: "resultThumbnailBot"), noImage: WMFRiveBool(path: "resultNoImgB"))
    }

    /// One slide: the guess, with the reveal as its answer. A tap on a card replaces the guess with the
    /// reveal in place. No slide without two rabbit holes.
    func rabbitHoleSlides(_ slideData: WMFYearInReviewRabbitHolesSlideData?) -> [WMFYearInReviewSlideViewModel] {
        guard let slideData, case let (deepest, other)? = SlideEligibility.rabbitHoles(slideData) else {
            return []
        }
        let (topCard, bottomCard) = slideData.deepestIsOnTop ? (deepest, other) : (other, deepest)
        return [rabbitHoleGuessSlide(topCard: topCard, bottomCard: bottomCard, reveal: rabbitHoleRevealSlide(deepest))]
    }

    private func rabbitHoleGuessSlide(topCard: WMFYearInReviewRabbitHolesSlideData.RabbitHole, bottomCard: WMFYearInReviewRabbitHolesSlideData.RabbitHole, reveal: WMFYearInReviewSlideViewModel) -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewRabbitHoleTitle
        let articles: [(RabbitHolePath.Article, WMFYearInReviewRabbitHolesSlideData.Article)] = [
            (RabbitHolePath.topCardFirst, topCard.firstArticle),
            (RabbitHolePath.topCardLast, topCard.lastArticle),
            (RabbitHolePath.bottomCardFirst, bottomCard.firstArticle),
            (RabbitHolePath.bottomCardLast, bottomCard.lastArticle)
        ]
        let cardLabels = [topCard, bottomCard].map { rabbitHoleAccessibilityLabel($0) }
        return rabbitHoleSlide(
            id: "rabbitHoleGuess",
            artboard: "frame11a",
            headline: headline,
            bodyText: nil,
            articles: articles,
            answer: reveal,
            answerTrigger: RabbitHolePath.frameComplete,
            sharePoseTime: RabbitHolePath.guessSharePoseTime,
            accessibilityLabel: ([headline] + cardLabels).joined(separator: " ")
        )
    }

    private func rabbitHoleRevealSlide(_ rabbitHole: WMFYearInReviewRabbitHolesSlideData.RabbitHole) -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewRabbitHoleRevealTitle(articleCount: rabbitHole.articleCount)
        let bodyText = CommonStrings.yearInReviewRabbitHoleRevealSubtitle
        return rabbitHoleSlide(
            id: "rabbitHoleReveal",
            artboard: "frame11b",
            headline: headline,
            bodyText: bodyText,
            articles: [
                (RabbitHolePath.resultFirst, rabbitHole.firstArticle),
                (RabbitHolePath.resultLast, rabbitHole.lastArticle)
            ],
            accessibilityLabel: "\(headline) \(rabbitHoleAccessibilityLabel(rabbitHole)) \(bodyText)"
        )
    }

    private func rabbitHoleAccessibilityLabel(_ rabbitHole: WMFYearInReviewRabbitHolesSlideData.RabbitHole) -> String {
        "\(rabbitHole.firstArticle.title), \(rabbitHole.lastArticle.title)."
    }

    private func rabbitHoleSlide(
        id: String,
        artboard: String,
        headline: String,
        bodyText: String?,
        articles: [(RabbitHolePath.Article, WMFYearInReviewRabbitHolesSlideData.Article)],
        answer: WMFYearInReviewSlideViewModel? = nil,
        answerTrigger: WMFRiveTrigger? = nil,
        sharePoseTime: TimeInterval? = nil,
        accessibilityLabel: String
    ) -> WMFYearInReviewSlideViewModel {
        var text = [RabbitHolePath.headline: headline]
        if let bodyText {
            text[RabbitHolePath.bodyText] = bodyText
        }
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        var missingImageFlags: [WMFRiveImage: WMFRiveBool] = [:]
        for (path, article) in articles {
            text[path.title] = article.title
            missingImageFlags[path.thumbnail] = path.noImage
            if let project = article.project {
                thumbnails[path.thumbnail] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: project, title: article.title)
            }
        }
        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: Self.loggingID(forSlideID: id),
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: "\(artboard)-statemachine"),
            text: text,
            articleThumbnails: thumbnails,
            missingImageFlags: missingImageFlags,
            answer: answer,
            answerTrigger: answerTrigger,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            sharePoseTime: sharePoseTime
        )
    }

    // MARK: - Eligibility

    /// When each personalized slide shows its data. The slides and the highlights both read these
    /// rules, so the highlights image only shows what the slides showed. Each rule returns `nil`
    /// when the slide shows its empty version, or no slide.
    enum SlideEligibility {

        /// The total articles slide needs at least `WMFYearInReviewReadData.minimumReadCount` articles.
        /// The highlights do not use this rule: they show the count from `minimumHighlightsReadCount`.
        static func readCount(_ readCount: Int) -> Int? {
            readCount >= WMFYearInReviewReadData.minimumReadCount ? readCount : nil
        }

        /// No slide shows the minutes yet. The highlights show them when there are any.
        static func minutesRead(_ minutesRead: Int) -> Int? {
            minutesRead > 0 ? minutesRead : nil
        }

        /// The reread articles slide needs at least two articles visited multiple times.
        static func rereadArticles(_ articles: [RereadArticle]) -> [RereadArticle]? {
            articles.count >= WMFYearInReviewTopArticlesSlideData.minimumArticleCount ? articles : nil
        }

        /// The rabbit hole slide needs two rabbit holes: the deepest, then the other.
        static func rabbitHoles(_ slideData: WMFYearInReviewRabbitHolesSlideData) -> (deepest: WMFYearInReviewRabbitHolesSlideData.RabbitHole, other: WMFYearInReviewRabbitHolesSlideData.RabbitHole)? {
            guard slideData.isEligible,
                  let deepest = slideData.rabbitHoles.first,
                  let other = slideData.rabbitHoles.dropFirst().first else {
                return nil
            }
            return (deepest, other)
        }

        /// The niche interest slide needs a category name.
        static func nicheCategoryName(_ slideData: WMFYearInReviewNicheCategorySlideData?) -> String? {
            guard let slideData, slideData.isEligible else {
                return nil
            }
            return slideData.categoryName
        }
    }

    // MARK: - Highlights

    /// The highlights show the article count from this number of articles. It is lower than the
    /// minimum of the total articles slide. See `highlights(readData:rereadArticles:rabbitHoles:nicheCategory:)`.
    static let minimumHighlightsReadCount = 1

    /// The highlights from the same data as the personalized slides.
    func highlights(from data: PersonalizedData) -> WMFYearInReviewHighlights {
        highlights(
            readData: data.readData,
            rereadArticles: data.rereadArticles,
            rabbitHoles: data.rabbitHoles,
            nicheCategory: data.nicheCategory
        )
    }

    /// Each highlight follows the rules of its slide, so the image only shows what the slides showed.
    /// One exception: the article count shows from one article, also when the total articles slide
    /// showed its empty version. Product decided this, so the count is part of more shared images.
    func highlights(readData: WMFYearInReviewReadData?, rereadArticles: [RereadArticle], rabbitHoles: WMFYearInReviewRabbitHolesSlideData?, nicheCategory: WMFYearInReviewNicheCategorySlideData?) -> WMFYearInReviewHighlights {
        let articlesRead = readData.flatMap { $0.readCount >= Self.minimumHighlightsReadCount ? $0.readCount : nil }
        let minutesRead = readData.flatMap { SlideEligibility.minutesRead($0.minutesRead) }
        let rotation = SlideEligibility.rereadArticles(rereadArticles)?.map(\.title) ?? []
        let rabbitHole = rabbitHoles.flatMap { SlideEligibility.rabbitHoles($0)?.deepest }.map { deepest in
            WMFYearInReviewHighlights.RabbitHole(firstTitle: deepest.firstArticle.title, lastTitle: deepest.lastArticle.title)
        }
        return WMFYearInReviewHighlights(
            articlesRead: articlesRead,
            minutesRead: minutesRead,
            rotation: rotation,
            rabbitHole: rabbitHole,
            nicheCategory: SlideEligibility.nicheCategoryName(nicheCategory),
            localizedStrings: WMFYearInReviewHighlights.LocalizedStrings(
                title: CommonStrings.yearInReviewHighlightsTitle,
                articlesReadLabel: CommonStrings.yearInReviewHighlightsArticlesRead,
                minutesReadLabel: CommonStrings.yearInReviewHighlightsMinutesRead,
                rotationLabel: CommonStrings.yearInReviewHighlightsRotation,
                rotationRank: { CommonStrings.yearInReviewHighlightsRank($0) },
                rabbitHoleLabel: CommonStrings.yearInReviewHighlightsRabbitHole,
                nicheCategoryLabel: CommonStrings.yearInReviewHighlightsNicheCategory,
                createdWith: CommonStrings.yearInReviewHighlightsCreatedWith
            )
        )
    }

    // MARK: - Collective

    /// The slides about all readers and editors. The numbers come from the config, so they can
    /// change without an app release. The volunteer editors slide does not show without its number.
    func collectiveSlides(config: WMFFeatureConfigResponse.Common.YearInReview) -> [WMFYearInReviewSlideViewModel] {
        var slides = [
            collectiveNumberSlide(
                id: "collectiveHoursRead",
                artboard: "frame3",
                headline: CommonStrings.yearInReviewCollectiveHoursReadTitle,
                data: decimalString(config.hoursReadEN),
                bodyText: CommonStrings.yearInReviewCollectiveHoursReadSubtitle(yearCount: config.yearsReadEN)
            ),
            collectiveNumberSlide(
                id: "collectiveLanguages",
                artboard: "frame4",
                headline: CommonStrings.yearInReviewCollectiveLanguagesTitle,
                data: CommonStrings.yearInReviewCollectiveLanguagesData(languageCount: decimalString(config.languages)),
                bodyText: CommonStrings.yearInReviewCollectiveLanguagesSubtitle
            ),
            collectiveNumberSlide(
                id: "collectiveArticles",
                artboard: "frame17",
                headline: CommonStrings.yearInReviewCollectiveArticlesTitle,
                data: decimalString(config.articles),
                bodyText: CommonStrings.yearInReviewCollectiveArticlesSubtitle
            ),
            collectiveNumberSlide(
                id: "collectiveSavedArticles",
                artboard: "frame8",
                headline: CommonStrings.yearInReviewCollectiveSavedArticlesTitle,
                data: decimalString(config.savedArticlesApps),
                bodyText: CommonStrings.yearInReviewCollectiveSavedArticlesSubtitle
            )
        ]
        if let volunteerEditors = config.volunteerEditors {
            slides.append(collectiveNumberSlide(
                id: "collectiveEditors",
                artboard: "frame16",
                headline: CommonStrings.yearInReviewCollectiveEditorsTitle,
                data: decimalString(volunteerEditors),
                bodyText: CommonStrings.yearInReviewCollectiveEditorsSubtitle
            ))
        }
        slides.append(collectiveNumberSlide(
            id: "collectiveEdits",
            artboard: "frame5",
            headline: CommonStrings.yearInReviewCollectiveEditsTitle,
            data: decimalString(config.edits),
            bodyText: CommonStrings.yearInReviewCollectiveEditsSubtitle
        ))
        slides.append(globalReachSlide())
        return slides
    }

    private func collectiveNumberSlide(id: String, artboard: String, headline: String, data: String, bodyText: String) -> WMFYearInReviewSlideViewModel {
        dataSlide(
            id: id,
            artboard: artboard,
            stateMachine: "\(artboard)-statemachine",
            headline: headline,
            data: data,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(data). \(bodyText)"
        )
    }

    private func globalReachSlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewCollectiveGlobalReachTitle
        let reach = CommonStrings.yearInReviewCollectiveGlobalReachData
        let bodyText = CommonStrings.yearInReviewCollectiveGlobalReachSubtitle
        return dataSlide(
            id: "collectiveGlobalReach",
            artboard: "frame12",
            stateMachine: "frame12-statemachine",
            headline: headline,
            data: reach,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(reach). \(bodyText)"
        )
    }

    private func decimalString(_ number: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }

    // MARK: - Contributor

    struct ContributorStatus {
        let isEditor: Bool
        let isDonor: Bool
    }

    /// Edits come from the report, which has them only for a logged-in reader. Donations are stored
    /// on the device, so they are read now, and a donation made a moment ago counts.
    private func storedContributorStatus() -> ContributorStatus {
        let isDonor: Bool
        if let dateRange = WMFYearInReviewDataController.contributorDateRange(year: WMFYearInReviewDataController.targetYear),
           let donations = WMFDonateDataController.shared.loadLocalDonationHistory(startDate: dateRange.start, endDate: dateRange.end) {
            isDonor = !donations.isEmpty
        } else {
            isDonor = false
        }
        return ContributorStatus(isEditor: (storedEditCount() ?? 0) > 0, isDonor: isDonor)
    }

    /// The edits in the contributor period, from the report the app fills in the background. `nil`
    /// when the report does not have them.
    private func storedEditCount() -> Int? {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            let slides = report?.slides ?? []
            if let data = slides.first(where: { $0.id == .editCount })?.data,
               let editCount = try JSONDecoder().decode(Int?.self, from: data) {
                return editCount
            }
            if let data = slides.first(where: { $0.id == .donateCount })?.data {
                return try JSONDecoder().decode(DonateAndEditCounts.self, from: data).editCount
            }
            return nil
        } catch {
            DDLogError("Error reading the Year in Review edit count: \(error)")
            return nil
        }
    }

    /// Text fields on the `DataTemplate` view model of the `end` frame. `headline` and `data` are not used.
    private enum EndTextPath {
        static let title = WMFRiveText(path: "coverTitle")
        static let bodyCopy = WMFRiveText(path: "bodyCopy")
    }

    /// "Thank you" for a logged-in reader who edited or donated in the contributor period, with the
    /// donate button in the toolbar. Otherwise "You matter", with a primary donate button below the
    /// animation in place of the toolbar button.
    ///
    /// A logged-out reader always sees "You matter", also with a donation on the device, because the
    /// donor recognition requires log in (T441430).
    /// - Parameter hidesDonate: True where donations are not accepted. Then the "You matter" slide does not show.
    /// - Returns: `nil` when no slide shows.
    func contributorSlide(isEditor: Bool, isDonor: Bool, isLoggedIn: Bool, hidesDonate: Bool) -> WMFYearInReviewSlideViewModel? {
        guard isLoggedIn, isEditor || isDonor else {
            guard !hidesDonate else {
                return nil
            }
            let bodyText = isLoggedIn
                ? CommonStrings.yearInReviewYouMatterSubtitle
                : "\(CommonStrings.yearInReviewYouMatterSubtitle) \(CommonStrings.yearInReviewYouMatterLogInSubtitle)"
            return endSlide(id: Self.nonContributorSlideID, title: CommonStrings.yearInReviewYouMatterTitle, bodyText: bodyText, showsPrimaryDonateButton: true)
        }

        let bodyText: String
        switch (isEditor, isDonor) {
        case (true, true):
            bodyText = CommonStrings.yearInReviewThankYouEditorAndDonorSubtitle
        case (true, false):
            bodyText = CommonStrings.yearInReviewThankYouEditorSubtitle
        default:
            bodyText = CommonStrings.yearInReviewThankYouDonorSubtitle
        }
        return endSlide(id: Self.contributorSlideID, title: CommonStrings.yearInReviewThankYouTitle, bodyText: bodyText, showsPrimaryDonateButton: false)
    }

    static let contributorSlideID = "contributor"
    static let nonContributorSlideID = "nonContributor"

    private func endSlide(id: String, title: String, bodyText: String, showsPrimaryDonateButton: Bool) -> WMFYearInReviewSlideViewModel {
        WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: Self.loggingID(forSlideID: id),
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: "end", stateMachineName: "end-statemachine"),
            text: [
                // The title is shown in capitals. VoiceOver gets it as written.
                EndTextPath.title: title.localizedUppercase,
                EndTextPath.bodyCopy: bodyText
            ],
            localizedStrings: .init(accessibilityLabel: "\(title) \(bodyText)"),
            showsPrimaryDonateButton: showsPrimaryDonateButton,
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag
        )
    }

    // MARK: - List slides

    /// Text fields on the `List` view model in the templates file.
    private enum ListTextPath {
        static let headline = WMFRiveText(path: "headline")
        static let bodyText = WMFRiveText(path: "bodyText")

        static func articleTitle(_ number: Int) -> WMFRiveText {
            WMFRiveText(path: "articleTitle\(number)")
        }

        static func subTitle(_ number: Int) -> WMFRiveText {
            WMFRiveText(path: "subTitle\(number)")
        }
    }

    /// Image fields on the `List` view model in the templates file.
    private enum ListImagePath {
        static func icon(_ number: Int) -> WMFRiveImage {
            WMFRiveImage(path: "icon\(number)")
        }
    }

    /// One row on a list slide.
    private struct ListItem {
        let title: String
        let subtitle: String
    }

    private func listAccessibilityLabel(heading: String, items: [ListItem]) -> String {
        let itemLabels = items.map { item in
            item.subtitle.isEmpty ? "\(item.title)." : "\(item.title), \(item.subtitle)."
        }
        return ([heading] + itemLabels).joined(separator: " ")
    }

    /// Lays a list frame out from right to left for a right-to-left app language.
    private static let listLayoutDirection = WMFRiveLayoutDirection(property: WMFRiveEnum(path: "layoutDir"))

    /// The number of rows that a list frame shows. The frame hides the other rows.
    private static let numberOfListItems = WMFRiveNumber(path: "numOfListItems")

    /// The number of rows on a list frame.
    private static let maximumListItems = 3

    /// A list slide from the templates file. Pass `nil` for a text field that the frame does not
    /// use. The file has room for three items. Pass no items for a frame without rows.
    /// The headline is shown as written, not in capitals.
    private func listSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String?,
        bodyText: String?,
        items: [ListItem],
        articleThumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:],
        images: [WMFRiveImage: Data] = [:],
        accessibilityLabel: String
    ) -> WMFYearInReviewSlideViewModel {
        var text: [WMFRiveText: String] = [:]
        if let headline {
            text[ListTextPath.headline] = headline
        }
        if let bodyText {
            text[ListTextPath.bodyText] = bodyText
        }
        var numbers: [WMFRiveNumber: Double] = [:]
        if !items.isEmpty {
            let shownItems = Array(items.prefix(Self.maximumListItems))
            // A row that is not written keeps the copy inside the .riv ("initial value"), so clear the unused rows.
            let emptyRows = Array(repeating: ListItem(title: "", subtitle: ""), count: Self.maximumListItems - shownItems.count)
            for (number, item) in zip(1...Self.maximumListItems, shownItems + emptyRows) {
                text[ListTextPath.articleTitle(number)] = item.title
                text[ListTextPath.subTitle(number)] = item.subtitle
            }
            numbers[Self.numberOfListItems] = Double(shownItems.count)
        }

        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: Self.loggingID(forSlideID: id),
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            numbers: numbers,
            articleThumbnails: articleThumbnails,
            images: images,
            layoutDirection: Self.listLayoutDirection,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag
        )
    }

    // MARK: - Data slides

    /// Text fields on the `DataTemplate` view model in the templates file.
    private enum DataTextPath {
        static let headline = WMFRiveText(path: "headline")
        static let data = WMFRiveText(path: "data")
        static let bodyCopy = WMFRiveText(path: "bodyCopy")
    }

    /// A slide from the templates file that shows one number or one short text. Pass `nil` for a
    /// text field that the frame does not use. The data is shown in capitals, for example
    /// "WEDNESDAY EVENINGS". The headline is shown as written. The accessibility label keeps the
    /// text as written.
    private func dataSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String,
        data: String?,
        bodyText: String,
        images: [WMFRiveImage: Data] = [:],
        accessibilityLabel: String
    ) -> WMFYearInReviewSlideViewModel {
        var text: [WMFRiveText: String] = [
            DataTextPath.headline: headline,
            DataTextPath.bodyCopy: bodyText
        ]
        if let data {
            text[DataTextPath.data] = data.localizedUppercase
        }

        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: Self.loggingID(forSlideID: id),
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            images: images,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag
        )
    }

    /// Each template in the file sets this flag for the contrast of the controls above it. The style
    /// that the factory passes shows only until the slide loads.
    private static let lightContentFlag = WMFRiveBool(path: "isUIWhite")

    /// The file with the frame templates.
    private let templatesResourceName = "all_templates"
}
