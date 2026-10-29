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
            donateButtonTitle: CommonStrings.donateTitle,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            aboutInsightsButtonTitle: Self.aboutInsightsButtonTitle,
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle,
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    /// Only the total articles, days visited, articles visited multiple times, topic, rabbit hole, edit and contributor slides have real data so far.
    /// The personalized slides show the user's data, but a slide without enough data shows its empty version.
    /// The days visited, rabbit hole, edit views and most-viewed articles slides have no empty version, so they do not show without enough data.
    /// The collective slides show data for all readers. Every flow ends with the contributor slide,
    /// but only the personalized flow can end with "Thank you", the same as on Android.
    /// - Parameters:
    ///   - isLoggedIn: A logged-out non-contributor is asked to log in to see their contributions.
    ///   - forcesAllEmptyStates: shows the empty version of each personalized slide. Only the developer settings use it.
    func makeSlides(experience: WMFYearInReviewDataController.YiRSlidesExperience, isLoggedIn: Bool, forcesAllEmptyStates: Bool = false) -> [WMFYearInReviewSlideViewModel] {
        let contributorSlides = makeContributorSlide(experience: experience, isLoggedIn: isLoggedIn).map { [$0] } ?? []
        return experienceSlides(experience, isLoggedIn: isLoggedIn, forcesAllEmptyStates: forcesAllEmptyStates) + contributorSlides
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

    private func experienceSlides(_ experience: WMFYearInReviewDataController.YiRSlidesExperience, isLoggedIn: Bool, forcesAllEmptyStates: Bool) -> [WMFYearInReviewSlideViewModel] {
        switch experience {
        case .collective:
            // Without a config, Year in Review does not open, but never show zero slides.
            guard let config = try? WMFYearInReviewDataController().config else {
                return personalizedEmptySlides(isLoggedIn: isLoggedIn)
            }
            return collectiveSlides(config: config)
        case .personalized where forcesAllEmptyStates:
            return personalizedEmptySlides(isLoggedIn: isLoggedIn)
        case .personalized:
            // No stored data means no qualifying articles, so show the empty states, never zero slides.
            let config = try? WMFYearInReviewDataController().config
            let readCount = storedReadCount() ?? 0
            return personalizedSlides(PersonalizedData(
                readCount: readCount,
                topReadPercentage: config?.topReadPercentage(forReadCount: readCount),
                averageReadCount: config?.averageArticlesReadPerYear,
                daysVisited: storedDaysVisited(),
                topTopics: storedTopTopics(),
                rabbitHoles: storedRabbitHoles(),
                rereadArticles: storedRereadArticles() ?? [],
                isLoggedIn: isLoggedIn,
                editCount: storedEditCount(),
                editViewCount: storedViewCount(),
                mostViewedArticles: storedMostViewedArticles()
            ))
        }
    }

    /// The stored data of the personalized slides.
    struct PersonalizedData {
        var readCount = 0
        var topReadPercentage: Double?
        var averageReadCount: Int?
        var daysVisited: WMFYearInReviewDaysVisitedSlideData?
        var topTopics: WMFYearInReviewTopTopicsSlideData?
        var rabbitHoles: WMFYearInReviewRabbitHolesSlideData?
        var rereadArticles: [RereadArticle] = []
        /// The edit slides need an account.
        var isLoggedIn = false
        /// `nil` when the edit count was never fetched, for example after a failed request. Then no
        /// edit slide shows, so an editor is never told they made 0 edits.
        var editCount: Int?
        var editViewCount: Int?
        var mostViewedArticles: [WMFYearInReviewMostViewedArticlesSlideData.Article] = []
    }

    /// The personalized slides in the order of T438549. These slides are not built yet, so they are
    /// not in the flow: time spent, longest reading streak, reading pattern, biggest reading day,
    /// longest read, category, geography, saved and the end screen.
    func personalizedSlides(_ data: PersonalizedData) -> [WMFYearInReviewSlideViewModel] {
        var slides = [
            totalArticlesSlide(readCount: data.readCount, topReadPercentage: data.topReadPercentage, averageReadCount: data.averageReadCount)
        ]
        if let daysVisited = daysVisitedSlide(data.daysVisited) {
            slides.append(daysVisited)
        }
        slides += topicSlides(data.topTopics)
        slides += rabbitHoleSlides(data.rabbitHoles)
        slides.append(rereadArticlesSlide(data.rereadArticles))
        if data.isLoggedIn, let editCount = data.editCount {
            slides += editorSlides(editCount: editCount, viewCount: data.editViewCount, mostViewedArticles: data.mostViewedArticles)
        }
        return slides
    }

    /// In the same order as `personalizedSlides(_:)`.
    private func personalizedEmptySlides(isLoggedIn: Bool) -> [WMFYearInReviewSlideViewModel] {
        var slides = [totalArticlesEmptySlide(), topTopicEmptySlide(), rereadArticlesEmptySlide()]
        if isLoggedIn {
            slides.append(editsEmptySlide())
        }
        return slides
    }

    // MARK: - Total articles

    /// The number of unique articles read, from the report the app fills in the background.
    /// `nil` when the report does not have this slide yet.
    private func storedReadCount() -> Int? {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .readCount })?.data else {
                return nil
            }
            return try JSONDecoder().decode(WMFYearInReviewReadData.self, from: data).readCount
        } catch {
            DDLogError("Error reading the Year in Review total articles: \(error)")
            return nil
        }
    }

    /// Shows the empty version unless the reader read at least `WMFYearInReviewReadData.minimumReadCount` articles.
    /// - Parameters:
    ///   - topReadPercentage: The "top X%" of readers globally, for example `50` or `0.01`. `nil` when the reader is below the 50th percentile.
    ///   - averageReadCount: The number of articles the average person reads in a year.
    func totalArticlesSlide(readCount: Int, topReadPercentage: Double?, averageReadCount: Int?) -> WMFYearInReviewSlideViewModel {
        guard readCount >= WMFYearInReviewReadData.minimumReadCount else {
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
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .daysVisited })?.data else {
                return nil
            }
            return try JSONDecoder().decode(WMFYearInReviewDaysVisitedSlideData.self, from: data)
        } catch {
            DDLogError("Error reading the Year in Review days visited: \(error)")
            return nil
        }
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
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .topArticles })?.data else {
                return nil
            }
            let slideData = try JSONDecoder().decode(WMFYearInReviewTopArticlesSlideData.self, from: data)
            guard slideData.isEligible else {
                return []
            }
            return slideData.articles.map { RereadArticle(title: $0.title, visitCount: $0.visitCount, project: $0.project) }
        } catch {
            DDLogError("Error reading the Year in Review articles visited multiple times: \(error)")
            return nil
        }
    }

    /// Shows the empty version unless at least two articles were visited multiple times.
    func rereadArticlesSlide(_ articles: [RereadArticle]) -> WMFYearInReviewSlideViewModel {
        guard articles.count >= WMFYearInReviewTopArticlesSlideData.minimumArticleCount else {
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

    // MARK: - Topics

    /// The topic slides, from the report the app fills in the background. `nil` when the report
    /// does not have these slides yet.
    private func storedTopTopics() -> WMFYearInReviewTopTopicsSlideData? {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .topTopics })?.data else {
                return nil
            }
            return try JSONDecoder().decode(WMFYearInReviewTopTopicsSlideData.self, from: data)
        } catch {
            DDLogError("Error reading the Year in Review top topics: \(error)")
            return nil
        }
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
            dataFit: Self.dataTextFit,
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
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .rabbitHoles })?.data else {
                return nil
            }
            return try JSONDecoder().decode(WMFYearInReviewRabbitHolesSlideData.self, from: data)
        } catch {
            DDLogError("Error reading the Year in Review rabbit holes: \(error)")
            return nil
        }
    }

    /// Properties on the `Interaction2` view model in the templates file. On the guess frame, the
    /// top card and the bottom card each show the first article (T) and the last article (B) of
    /// a rabbit hole. The reveal frame shows the deepest rabbit hole with the result properties.
    private enum RabbitHolePath {
        static let headline = WMFRiveText(path: "headline")
        static let bodyText = WMFRiveText(path: "bodyText")
        /// The guess frame fires it after the reader taps a card and the exit animation ends.
        static let frameComplete = WMFRiveTrigger(path: "frameComplete")

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
        guard let slideData,
              slideData.isEligible,
              let deepest = slideData.rabbitHoles.first,
              let other = slideData.rabbitHoles.dropFirst().first else {
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
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: "\(artboard)-statemachine"),
            text: text,
            articleThumbnails: thumbnails,
            missingImageFlags: missingImageFlags,
            answer: answer,
            answerTrigger: answerTrigger,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.copyFits(headline: RabbitHolePath.headline, bodyText: RabbitHolePath.bodyText)
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
                dataFit: Self.collectiveDataNumberFit,
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
                dataFit: Self.collectiveDataNumberFit,
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
                dataFit: Self.collectiveDataNumberFit,
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

    /// The design sets a smaller number on these frames, so long numbers keep the same size.
    private static let collectiveDataNumberFit = WMFRiveTextFit(
        text: DataTextPath.data,
        fontAssetName: "SanSerifFont",
        maximumWidth: 344,
        maximumLines: 1,
        globalViewModelName: "GlobalProperties",
        fontSize: WMFRiveNumber(path: "dataNumberFontSize"),
        lineHeight: WMFRiveNumber(path: "dataNumbersLineHeight"),
        maximumFontSize: 40
    )

    private func collectiveNumberSlide(id: String, artboard: String, headline: String, data: String, dataFit: WMFRiveTextFit = Self.dataNumberFit, bodyText: String) -> WMFYearInReviewSlideViewModel {
        dataSlide(
            id: id,
            artboard: artboard,
            stateMachine: "\(artboard)-statemachine",
            headline: headline,
            data: data,
            dataFit: dataFit,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(data). \(bodyText)"
        )
    }

    /// The design shows the reach on three lines.
    private static let globalReachFit = WMFRiveTextFit(
        text: DataTextPath.data,
        fontAssetName: "SanSerifFont",
        maximumWidth: 344,
        maximumLines: 3,
        globalViewModelName: "GlobalProperties",
        fontSize: WMFRiveNumber(path: "dataTextFontSize"),
        lineHeight: WMFRiveNumber(path: "dataTextLineHeight")
    )

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
            dataFit: Self.globalReachFit,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(reach). \(bodyText)"
        )
    }

    private func decimalString(_ number: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }

    // MARK: - Edits

    /// The edits slide shows with its empty version for a reader without edits. The views slide and
    /// the most-viewed articles slide hide without enough views.
    private func editorSlides(editCount: Int, viewCount: Int?, mostViewedArticles: [WMFYearInReviewMostViewedArticlesSlideData.Article]) -> [WMFYearInReviewSlideViewModel] {
        var slides = [editsSlide(editCount: editCount)]
        if let editViews = editViewsSlide(viewCount: viewCount) {
            slides.append(editViews)
        }
        if let mostViewed = mostViewedArticlesSlide(mostViewedArticles) {
            slides.append(mostViewed)
        }
        return slides
    }

    /// The edits slide, or its empty version for fewer than one edit.
    func editsSlide(editCount: Int) -> WMFYearInReviewSlideViewModel {
        guard editCount >= 1 else {
            return editsEmptySlide()
        }
        let headline = CommonStrings.yearInReviewEditsTitle
        let count = decimalString(editCount)
        let bodyText = CommonStrings.yearInReviewEditsSubtitle
        return dataSlide(
            id: "edits",
            artboard: "frame16",
            stateMachine: "frame16-statemachine",
            headline: headline,
            data: count,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(count). \(bodyText)"
        )
    }

    private func editsEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = CommonStrings.yearInReviewEditsEmptyTitle
        let bodyText = CommonStrings.yearInReviewEditsEmptySubtitle
        return dataSlide(
            id: "editsEmpty",
            artboard: "frame16-empty",
            stateMachine: "frame16-empty-statemachine",
            headline: headline,
            data: nil,
            bodyText: bodyText,
            accessibilityLabel: "\(headline). \(bodyText)"
        )
    }

    // MARK: - Edit views

    /// The views on the articles the reader edited, from the report the app fills in the background.
    /// `nil` when the report does not have them.
    private func storedViewCount() -> Int? {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .viewCount })?.data else {
                return nil
            }
            return try JSONDecoder().decode(Int?.self, from: data)
        } catch {
            DDLogError("Error reading the Year in Review edit views: \(error)")
            return nil
        }
    }

    /// `nil` unless the edited articles have more than `WMFYearInReviewViewCountSlideRules.minimumViewCount` views.
    /// The slide has no empty version.
    func editViewsSlide(viewCount: Int?) -> WMFYearInReviewSlideViewModel? {
        guard let viewCount, viewCount > WMFYearInReviewViewCountSlideRules.minimumViewCount else {
            return nil
        }
        let headline = CommonStrings.yearInReviewEditViewsTitle
        let count = decimalString(viewCount)
        let bodyText = CommonStrings.yearInReviewEditViewsSubtitle
        return dataSlide(
            id: "editViews",
            artboard: "frame17",
            stateMachine: "frame17-statemachine",
            headline: headline,
            data: count,
            bodyText: bodyText,
            accessibilityLabel: "\(headline) \(count). \(bodyText)"
        )
    }

    // MARK: - Most-viewed articles

    private func storedMostViewedArticles() -> [WMFYearInReviewMostViewedArticlesSlideData.Article] {
        do {
            let report = try WMFYearInReviewDataController().fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear)
            guard let data = report?.slides.first(where: { $0.id == .mostViewedArticles })?.data else {
                return []
            }
            return try JSONDecoder().decode(WMFYearInReviewMostViewedArticlesSlideData.self, from: data).articles
        } catch {
            DDLogError("Error reading the Year in Review most-viewed articles: \(error)")
            return []
        }
    }

    /// `nil` without articles. The slide has no empty version.
    func mostViewedArticlesSlide(_ articles: [WMFYearInReviewMostViewedArticlesSlideData.Article]) -> WMFYearInReviewSlideViewModel? {
        let shownArticles = Array(articles.prefix(Self.maximumListItems))
        guard !shownArticles.isEmpty else {
            return nil
        }

        let bodyText = CommonStrings.yearInReviewMostViewedEditedArticlesTitle
        let items = shownArticles.map { article in
            ListItem(title: article.title, subtitle: CommonStrings.yearInReviewMostViewedEditedArticlesViewCount(article.viewsCount))
        }
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        for (index, article) in shownArticles.enumerated() {
            guard let project = article.project else { continue }
            thumbnails[ListImagePath.icon(index + 1)] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: project, title: article.title)
        }
        return listSlide(
            id: "mostViewedArticles",
            artboard: "frame18",
            stateMachine: "frame18-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            articleThumbnails: thumbnails,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
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

    /// The title and the body copy grow, so long copy can push the content past the bottom of the
    /// slide. Same rule as the copy on the other slides.
    private static let endTextFits: [WMFRiveTextFit] = [
        WMFRiveTextFit(
            text: EndTextPath.title,
            fontAssetName: "SanSerifFont",
            maximumWidth: copyWidth,
            maximumLines: 3,
            minimumScale: copyMinimumScale,
            group: "copy",
            globalViewModelName: "GlobalProperties",
            fontSize: WMFRiveNumber(path: "coverGlyphsFontSize"),
            lineHeight: WMFRiveNumber(path: "coverGlyphsLineHeight")
        ),
        WMFRiveTextFit(
            text: EndTextPath.bodyCopy,
            fontAssetName: "SerifFont",
            maximumWidth: copyWidth,
            maximumLines: 6,
            minimumScale: copyMinimumScale,
            group: "copy",
            globalViewModelName: "GlobalProperties",
            fontSize: WMFRiveNumber(path: "bodyCopyFontSize"),
            lineHeight: WMFRiveNumber(path: "bodyCopyLineHeight")
        )
    ]

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
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: "end", stateMachineName: "end-statemachine"),
            text: [
                // The title is shown in capitals. VoiceOver gets it as written.
                EndTextPath.title: title.localizedUppercase,
                EndTextPath.bodyCopy: bodyText
            ],
            localizedStrings: .init(accessibilityLabel: "\(title) \(bodyText)"),
            showsPrimaryDonateButton: showsPrimaryDonateButton,
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.endTextFits
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
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            numbers: numbers,
            articleThumbnails: articleThumbnails,
            images: images,
            layoutDirection: Self.listLayoutDirection,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.copyFits(headline: ListTextPath.headline, bodyText: ListTextPath.bodyText)
        )
    }

    // MARK: - Data slides

    /// Text fields on the `DataTemplate` view model in the templates file.
    private enum DataTextPath {
        static let headline = WMFRiveText(path: "headline")
        static let data = WMFRiveText(path: "data")
        static let bodyCopy = WMFRiveText(path: "bodyCopy")
    }

    /// The box of the large number does not grow, so a long number wraps on top of the body copy.
    /// Make the number smaller until it fits on one line. The width is the width of the
    /// `Data-Numbers` artboard in the templates file.
    private static let dataNumberFit = WMFRiveTextFit(
        text: DataTextPath.data,
        fontAssetName: "SanSerifFont",
        maximumWidth: 344,
        maximumLines: 1,
        globalViewModelName: "GlobalProperties",
        fontSize: WMFRiveNumber(path: "dataNumberFontSize"),
        lineHeight: WMFRiveNumber(path: "dataNumbersLineHeight")
    )

    /// The box of the data text, for example a topic name, does not grow. Make the text smaller
    /// until it fits on one line. The width is the width of the `Data-Text` artboard in the
    /// templates file.
    private static let dataTextFit = WMFRiveTextFit(
        text: DataTextPath.data,
        fontAssetName: "SanSerifFont",
        maximumWidth: 344,
        maximumLines: 1,
        globalViewModelName: "GlobalProperties",
        fontSize: WMFRiveNumber(path: "dataTextFontSize"),
        lineHeight: WMFRiveNumber(path: "dataTextLineHeight")
    )

    /// A slide from the templates file that shows one number or one short text. Pass `nil` for a
    /// text field that the frame does not use. The data is shown in capitals, for example
    /// "WEDNESDAY EVENINGS". The headline is shown as written. The accessibility label keeps the
    /// text as written.
    /// - Parameter dataFit: The fit of `data`. A number uses `dataNumberFit`, and a text uses `dataTextFit`.
    private func dataSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String,
        data: String?,
        dataFit: WMFRiveTextFit = Self.dataNumberFit,
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
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            images: images,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.copyFits(headline: DataTextPath.headline, bodyText: DataTextPath.bodyCopy) + (data == nil ? [] : [dataFit])
        )
    }

    // MARK: - Text size

    /// The headline and the body copy grow, so long copy can push the content past the bottom of the
    /// slide. Over these line counts, make both smaller by the same scale, to at most `copyMinimumScale`. The width
    /// is smaller than the text boxes on any frame, so the line counts are safe.
    private static func copyFits(headline: WMFRiveText, bodyText: WMFRiveText) -> [WMFRiveTextFit] {
        [
            WMFRiveTextFit(
                text: headline,
                fontAssetName: "SerifFont",
                maximumWidth: copyWidth,
                maximumLines: 3,
                minimumScale: copyMinimumScale,
                group: "copy",
                globalViewModelName: "GlobalProperties",
                fontSize: WMFRiveNumber(path: "headlineFontSize"),
                lineHeight: WMFRiveNumber(path: "headlineLineHeight")
            ),
            WMFRiveTextFit(
                text: bodyText,
                fontAssetName: "SerifFont",
                maximumWidth: copyWidth,
                maximumLines: 4,
                minimumScale: copyMinimumScale,
                group: "copy",
                globalViewModelName: "GlobalProperties",
                fontSize: WMFRiveNumber(path: "bodyCopyFontSize"),
                lineHeight: WMFRiveNumber(path: "bodyCopyLineHeight")
            )
        ]
    }

    /// In artboard units. The headline and body boxes are about 296 to 320 wide.
    private static let copyWidth = 290.0

    /// The smallest scale of the headline and the body copy. At 75%, the longest copy that was
    /// tested (Russian, October 2026) filled the iPhone SE slide to its bottom edge, so 70% keeps
    /// a margin.
    static let copyMinimumScale = 0.7

    /// Each template in the file sets this flag for the contrast of the controls above it. The style
    /// that the factory passes shows only until the slide loads.
    private static let lightContentFlag = WMFRiveBool(path: "isUIWhite")

    /// The file with the frame templates.
    private let templatesResourceName = "all_templates"
}
