import Foundation
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Makes the content that the Year in Review view model is built from.
struct YearInReviewSlideViewModelFactory {

    // MARK: - Slide data

    /// What the slides show. A `nil` field leaves that slide out. A field with nothing in it (a count
    /// of 0, an empty list, no streak) shows the slide's empty version.
    struct SlideData {

        struct ArticleCount {
            let count: Int
            /// The reader is in the top this-many percent of readers. `nil` when the count is below
            /// every range in the config.
            let percentile: Double?
        }

        struct ReadingPeak {
            /// 1 is January.
            let month: Int
            let dayCount: Int
        }

        struct Streak {
            let dayCount: Int
            let start: Date
            let end: Date
        }

        struct FavoriteTime {
            /// 0 to 23.
            let hour: Int
            let percent: Int
        }

        struct BiggestReadingDay {
            let date: Date
            let minutes: Int
        }

        struct ReadingActivity {
            let dayCount: Int
            let peak: ReadingPeak?
            let longestStreak: Streak?
            let biggestReadingDay: BiggestReadingDay?
            let favoriteTime: FavoriteTime?
        }

        struct Topic {
            /// The topic name before translation.
            let name: String
            let articleCount: Int
            let exampleArticleTitles: [String]
        }

        struct Article {
            let title: String
            let description: String?
        }

        struct ViewedArticle {
            let title: String
            let viewCount: Int?
        }

        struct SavedArticles {
            let count: Int
            let articles: [ViewedArticle]
        }

        var articleCount: ArticleCount?
        var averageArticleCount: Int?
        var minutesRead: Int?
        var readingActivity: ReadingActivity?
        /// The first is the top topic. The rest are the runners-up.
        var topics: [Topic]?
        var sampleArticles: [Article]?
        var rereadArticles: [Article]?
        var savedArticles: SavedArticles?
        var editCount: Int?
        var editViewCount: Int?
        var mostViewedEditedArticles: [ViewedArticle]?

        // TEMPORARY: made-up values from the design file, so every full version shows.
        static func mock(calendar: Calendar = .current) -> SlideData {
            let year = WMFYearInReviewDataController.targetYear

            func date(month: Int, day: Int) -> Date? {
                calendar.date(from: DateComponents(year: year, month: month, day: day))
            }

            var streak: Streak?
            if let start = date(month: 3, day: 4), let end = date(month: 3, day: 14) {
                streak = Streak(dayCount: 11, start: start, end: end)
            }

            let biggestReadingDay = date(month: 3, day: 7).map { BiggestReadingDay(date: $0, minutes: 43) }

            let articles = [
                Article(title: "Pamela Anderson", description: "American supermodel"),
                Article(title: "Pamukkale", description: "Natural site in Denizli Province in southwestern Turkey"),
                Article(title: "Catherine, Princess of Wales", description: "A member of the British royal family.")
            ]

            var data = SlideData()
            data.articleCount = ArticleCount(count: 350, percentile: 50)
            data.averageArticleCount = 335
            data.minutesRead = 924
            data.readingActivity = ReadingActivity(
                dayCount: 47,
                peak: ReadingPeak(month: 12, dayCount: 20),
                longestStreak: streak,
                biggestReadingDay: biggestReadingDay,
                favoriteTime: FavoriteTime(hour: 19, percent: 50)
            )
            data.topics = [
                Topic(name: WMFArticleTopic.history.rawValue, articleCount: 23, exampleArticleTitles: ["Battle of Gettysburg", "Xia Dynasty"]),
                Topic(name: WMFArticleTopic.centralAmerica.rawValue, articleCount: 14, exampleArticleTitles: []),
                Topic(name: WMFArticleTopic.visualArts.rawValue, articleCount: 12, exampleArticleTitles: []),
                Topic(name: WMFArticleTopic.politicsAndGovernment.rawValue, articleCount: 8, exampleArticleTitles: [])
            ]
            data.sampleArticles = articles
            data.rereadArticles = articles
            data.savedArticles = SavedArticles(count: 26, articles: [
                ViewedArticle(title: "Pamela Anderson", viewCount: 230),
                ViewedArticle(title: "Pamukkale", viewCount: 200),
                ViewedArticle(title: "Catherine, Princess of Wales", viewCount: 185)
            ])
            data.editCount = 357
            data.editViewCount = 14791
            data.mostViewedEditedArticles = [
                ViewedArticle(title: "Pamela Anderson", viewCount: 200),
                ViewedArticle(title: "Pamukkale", viewCount: 150),
                ViewedArticle(title: "Catherine, Princess of Wales", viewCount: 50)
            ]
            return data
        }

        // TEMPORARY: nothing in any field, so every slide with an empty version shows it and the
        // rest are left out. Stands in for the collective slides until their frames exist.
        static var mockEmpty: SlideData {
            var data = SlideData()
            data.articleCount = ArticleCount(count: 0, percentile: nil)
            data.readingActivity = ReadingActivity(dayCount: 0, peak: nil, longestStreak: nil, biggestReadingDay: nil, favoriteTime: nil)
            data.topics = []
            data.sampleArticles = []
            data.rereadArticles = []
            data.savedArticles = SavedArticles(count: 0, articles: [])
            data.editCount = 0
            data.mostViewedEditedArticles = []
            return data
        }
    }

    func makeLocalizedStrings() -> WMFYearInReviewViewModel.LocalizedStrings {
        WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: CommonStrings.plainWikipediaName,
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: CommonStrings.moreButton,
            shareButtonTitle: CommonStrings.shortShareTitle,
            donateButtonTitle: CommonStrings.donateTitle,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle,
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    /// The slides for `flow`. `nil` is the profile entry point, which does not pick a flow.
    ///
    /// TEMPORARY: every slide uses dummy data. Personalized shows the full versions, collective shows
    /// the empty versions until the collective frames exist.
    func makeSlides(for flow: YearInReviewCoordinator.Flow? = nil) -> [WMFYearInReviewSlideViewModel] {
        let showsFullVersions: Bool
        switch flow {
        case .personalized:
            showsFullVersions = true
        case .collective:
            showsFullVersions = false
        case nil:
            showsFullVersions = forcedUserDataState != .lowData
        }

        return makePersonalizedSlides(data: showsFullVersions ? SlideData.mock() : SlideData.mockEmpty)
    }

    /// The developer settings data state, only while the Year in Review toggle is on. Same rule as
    /// `WMFYearInReviewDataController.fetchUserDataState()`.
    private var forcedUserDataState: WMFYearInReviewDataController.YiRUserDataState? {
        let developerSettings = WMFDeveloperSettingsDataController.shared
        guard developerSettings.forceYiREntryPoint2026 else {
            return nil
        }
        return developerSettings.forceYiRUserDataState
    }

    // MARK: - Personalized slides

    /// In the order of the design sheet. Frames 10, 11, 13, 14 and 19 are not in the sheet yet.
    private func makePersonalizedSlides(data: SlideData) -> [WMFYearInReviewSlideViewModel] {
        let slides: [WMFYearInReviewSlideViewModel?] = [
            data.articleCount.map { articleCountSlide($0, averageCount: data.averageArticleCount) },
            data.readingActivity.flatMap { readingDaysSlide($0) },
            data.minutesRead.flatMap { minutesReadSlide($0) },
            data.readingActivity.map { streakSlide($0.longestStreak) },
            data.readingActivity.map { favoriteTimeSlide($0.favoriteTime) },
            data.topics.map { topTopicSlide($0.first) },
            data.topics.flatMap { runnerUpTopicsSlide(Array($0.dropFirst())) },
            data.readingActivity?.biggestReadingDay.map { biggestReadingDaySlide($0) },
            data.sampleArticles.flatMap { sampleArticlesSlide($0) },
            data.rereadArticles.map { rereadArticlesSlide($0) },
            data.savedArticles.map { savedArticlesSlide($0) },
            data.editCount.map { editCountSlide($0) },
            data.editViewCount.map { editViewsSlide($0) },
            data.mostViewedEditedArticles.flatMap { mostViewedEditsSlide($0) }
        ]

        return slides.compactMap { $0 }
    }

    // MARK: - Slides

    // TEMPORARY: the sentences below are English stand-ins from the copy sheet. They become
    // WMFLocalizedString with plural rules once the copy is final.

    private func articleCountSlide(_ articleCount: SlideData.ArticleCount, averageCount: Int?) -> WMFYearInReviewSlideViewModel {
        guard articleCount.count > 0 else {
            let headline = "You have millions of articles to discover"
            let body = "Just wait until you find out all there is to learn on Wikipedia."
            return templateSlide(
                id: "articleCountEmpty",
                artboard: "frame1-empty",
                stateMachine: "frame1-empty-statemachine",
                headline: headline,
                data: nil,
                body: body,
                accessibilityLabel: "\(headline). \(body)",
                showsShareButton: false
            )
        }

        let headline = "Your total article count:"
        let count = formatted(articleCount.count)
        let body: String
        if let percentile = articleCount.percentile, let averageCount {
            body = "That puts you in the top \(formattedPercent(percentile)) of Wikipedia readers globally. The average person reads \(formatted(averageCount)) articles a year."
        } else {
            body = "You've been exploring all year. Every article added something to what you know."
        }

        return templateSlide(
            id: "articleCount",
            artboard: "frame1",
            stateMachine: "frame1-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline) \(count). \(body)",
            showsShareButton: false
        )
    }

    /// Left out when there are no reading days, since the frame has no empty version.
    private func readingDaysSlide(_ activity: SlideData.ReadingActivity) -> WMFYearInReviewSlideViewModel? {
        guard activity.dayCount > 0, let peak = activity.peak else {
            return nil
        }

        let headline = "Days you visited Wikipedia in \(year):"
        let count = formatted(activity.dayCount)
        let body = "Your activity peaked in \(monthName(peak.month)), when you read on \(formatted(peak.dayCount)) different days."
        return templateSlide(
            id: "readDays",
            artboard: "frame2",
            stateMachine: "frame2-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline) \(count). \(body)"
        )
    }

    /// Left out below 1 minute, the lowest threshold in the copy sheet.
    private func minutesReadSlide(_ minutes: Int) -> WMFYearInReviewSlideViewModel? {
        guard minutes >= 1 else {
            return nil
        }

        let headline = "Total minutes spent reading:"
        let count = formatted(minutes)
        let body = "\(minutesComparison(minutes)) Time flies when you're falling down a rabbit hole."
        return templateSlide(
            id: "minutesRead",
            artboard: "frame3",
            stateMachine: "frame3-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline) \(count). \(body)"
        )
    }

    /// The comparison for the highest threshold `minutes` reaches, from the minutes copy sheet.
    private func minutesComparison(_ minutes: Int) -> String {
        if minutes >= 2800 {
            // The sheet caps the day count at 300.
            let dayCount = min(minutes / (24 * 60), 300)
            return "That's longer than \(formatted(dayCount)) entire days."
        }

        let comparisons: [(minimumMinutes: Int, copy: String)] = [
            (1441, "That's longer than it takes a queen honeybee to lay up to 2,000 eggs."),
            (540, "That's longer than a full night's sleep."),
            (121, "That's longer than the current marathon world record."),
            (93, "That's longer than it takes the International Space Station to orbit Earth once."),
            (31, "That's longer than a sitcom episode, commercials and all."),
            (19, "That's longer than the average time it takes people to fall asleep."),
            (13, "That's longer than it takes to hard-boil an egg."),
            (9, "That's longer than it takes sunlight to travel from the sun to Earth."),
            (1, "That's longer than it takes a hummingbird's heart to beat 1,200 times.")
        ]

        return comparisons.first { minutes >= $0.minimumMinutes }?.copy ?? ""
    }

    private func streakSlide(_ streak: SlideData.Streak?) -> WMFYearInReviewSlideViewModel {
        guard let streak else {
            let headline = "0 reading streaks... yet"
            let body = "It's not a streak until you've done it for 3 consecutive days. Why not start now?"
            return templateSlide(
                id: "streakEmpty",
                artboard: "frame4-empty",
                stateMachine: "frame4-empty-statemachine",
                headline: headline,
                data: nil,
                body: body,
                accessibilityLabel: "\(headline). \(body)",
                showsShareButton: false
            )
        }

        let headline = "Days in your longest reading streak"
        let count = formatted(streak.dayCount)
        let body = "From \(formattedDateRange(from: streak.start, to: streak.end)), you really got into the groove of reading every day."
        return templateSlide(
            id: "streak",
            artboard: "frame4",
            stateMachine: "frame4-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline): \(count). \(body)"
        )
    }

    private func favoriteTimeSlide(_ favoriteTime: SlideData.FavoriteTime?) -> WMFYearInReviewSlideViewModel {
        guard let favoriteTime else {
            let headline = "You read basically whenever"
            let body = "There's no set day or time when to decide to explore the pages of Wikipedia."
            return templateSlide(
                id: "favoriteTimeEmpty",
                artboard: "frame5-empty",
                stateMachine: "frame5-empty-statemachine",
                headline: headline,
                data: nil,
                body: body,
                accessibilityLabel: "\(headline). \(body)",
                showsShareButton: false
            )
        }

        // TODO: Group hours into times of day ("Evenings") once design says which hours each covers.
        let headline = "Favorite time to explore:"
        let time = hourName(favoriteTime.hour)
        let body = "\(formattedPercent(Double(favoriteTime.percent))) of your exploring occurred during this time of day. Coincidence or...not?"
        return templateSlide(
            id: "favoriteTime",
            artboard: "frame5",
            stateMachine: "frame5-statemachine",
            headline: headline,
            data: time.uppercased(with: .current),
            body: body,
            accessibilityLabel: "\(headline) \(time). \(body)"
        )
    }

    private func topTopicSlide(_ topic: SlideData.Topic?) -> WMFYearInReviewSlideViewModel {
        guard let topic else {
            let headline = "Your #1 topic of \(year) is... all of them"
            let body = "With so many interests, there's no one topic that defined your reading habits."
            return templateSlide(
                id: "topTopicEmpty",
                artboard: "frame6-empty",
                stateMachine: "frame6-empty-statemachine",
                headline: headline,
                data: nil,
                body: body,
                accessibilityLabel: "\(headline). \(body)",
                showsShareButton: false
            )
        }

        let headline = "Your top topic of \(year):"
        let name = topicDisplayName(topic.name)
        let tiedArticles = "\(formatted(topic.articleCount)) of your articles were tied to this theme."
        var sentences: [String] = []
        if topic.exampleArticleTitles.count >= 2 {
            sentences.append("From \(topic.exampleArticleTitles[0]) to \(topic.exampleArticleTitles[1]), \(tiedArticles)")
        } else {
            // TODO: Confirm with design what the body says with fewer than two articles.
            sentences.append(tiedArticles.prefix(1).uppercased() + tiedArticles.dropFirst())
        }
        if let articleTopic = articleTopic(named: topic.name) {
            sentences.append(topicLine(for: articleTopic))
        }
        let body = sentences.joined(separator: " ")

        return templateSlide(
            id: "topTopic",
            artboard: "frame6",
            stateMachine: "frame6-statemachine",
            headline: headline,
            data: name.uppercased(with: .current),
            body: body,
            accessibilityLabel: "\(headline) \(name). \(body)"
        )
    }

    /// Left out when there are no runners-up, since the frame has no empty version.
    private func runnerUpTopicsSlide(_ topics: [SlideData.Topic]) -> WMFYearInReviewSlideViewModel? {
        guard !topics.isEmpty else {
            return nil
        }

        let bodyText = "And your runners-up for \(year):"
        let items = topics.map { ListItem(title: topicDisplayName($0.name), subtitle: "\(formatted($0.articleCount)) articles") }
        return listSlide(
            id: "runnerUpTopics",
            artboard: "frame7",
            stateMachine: "frame7-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    private func biggestReadingDaySlide(_ day: SlideData.BiggestReadingDay) -> WMFYearInReviewSlideViewModel {
        let headline = "Biggest reading day:"
        let date = formattedMonthDay(day.date)
        let body = "You spent a total of \(formatted(day.minutes)) minutes on Wikipedia. How's that for being productive?"
        return templateSlide(
            id: "biggestReadingDay",
            artboard: "frame8",
            stateMachine: "frame8-statemachine",
            headline: headline,
            data: date.uppercased(with: .current),
            body: body,
            accessibilityLabel: "\(headline) \(date). \(body)"
        )
    }

    /// Left out when there are no articles, since the frame has no empty version.
    private func sampleArticlesSlide(_ articles: [SlideData.Article]) -> WMFYearInReviewSlideViewModel? {
        guard !articles.isEmpty else {
            return nil
        }

        let headline = "A taste of the articles you read:"
        let items = articles.map { ListItem(title: $0.title, subtitle: $0.description ?? "") }
        return listSlide(
            id: "articleSample",
            artboard: "frame9",
            stateMachine: "frame9-statemachine",
            headline: headline,
            bodyText: nil,
            items: items,
            accessibilityLabel: listAccessibilityLabel(heading: headline, items: items)
        )
    }

    private func rereadArticlesSlide(_ articles: [SlideData.Article]) -> WMFYearInReviewSlideViewModel {
        guard !articles.isEmpty else {
            let headline = "You're not a re-reader"
            let bodyText = "So much for looking at an article twice. You prefer novelty and falling down new rabbit holes."
            return listSlide(
                id: "rereadArticlesEmpty",
                artboard: "frame12-empty",
                stateMachine: "frame12-empty-statemachine",
                headline: headline,
                bodyText: bodyText,
                items: [],
                accessibilityLabel: "\(headline). \(bodyText)",
                showsShareButton: false
            )
        }

        let bodyText = "Some articles in your rotation:"
        let items = articles.map { ListItem(title: $0.title, subtitle: $0.description ?? "") }
        return listSlide(
            id: "rereadArticles",
            artboard: "frame12",
            stateMachine: "frame12-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    private func savedArticlesSlide(_ saved: SlideData.SavedArticles) -> WMFYearInReviewSlideViewModel {
        guard saved.count > 0 else {
            let headline = "You have 0 articles saved"
            let bodyText = "You currently have 0 articles saved. Look for the bookmark icon on an article, so you can read up on whatever... later."
            return listSlide(
                id: "savedArticlesEmpty",
                artboard: "frame15-empty",
                stateMachine: "frame15-empty-statemachine",
                headline: headline,
                bodyText: bodyText,
                items: [],
                accessibilityLabel: "\(headline). \(bodyText)",
                showsShareButton: false
            )
        }

        let bodyText = "Articles you saved for later: \(formatted(saved.count))"
        let items = saved.articles.map { article in
            ListItem(title: article.title, subtitle: article.viewCount.map { "\(formatted($0)) views" } ?? "")
        }
        return listSlide(
            id: "savedArticles",
            artboard: "frame15",
            stateMachine: "frame15-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    private func editCountSlide(_ editCount: Int) -> WMFYearInReviewSlideViewModel {
        guard editCount > 0 else {
            let headline = "You've made 0 edits so far"
            let body = "You haven't made any edits yet, but it's easy to learn how. Now's a good time to join the community that builds Wikipedia."
            return templateSlide(
                id: "editCountEmpty",
                artboard: "frame16-empty",
                stateMachine: "frame16-empty-statemachine",
                headline: headline,
                data: nil,
                body: body,
                accessibilityLabel: "\(headline). \(body)",
                showsShareButton: false
            )
        }

        let headline = "Edits you made:"
        let count = formatted(editCount)
        let body = "Whether you contribute to Wikipedia, Wikimedia Commons, or Wikidata, thank you for improving everyone's access to human knowledge."
        return templateSlide(
            id: "editCount",
            artboard: "frame16",
            stateMachine: "frame16-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline) \(count). \(body)"
        )
    }

    private func editViewsSlide(_ viewCount: Int) -> WMFYearInReviewSlideViewModel {
        let headline = "Views your edits received:"
        let count = formatted(viewCount)
        let body = "In \(year), readers from around the world saw the changes you made."
        return templateSlide(
            id: "editViews",
            artboard: "frame17",
            stateMachine: "frame17-statemachine",
            headline: headline,
            data: count,
            body: body,
            accessibilityLabel: "\(headline) \(count). \(body)"
        )
    }

    /// Left out when there are no articles, since the frame has no empty version.
    private func mostViewedEditsSlide(_ articles: [SlideData.ViewedArticle]) -> WMFYearInReviewSlideViewModel? {
        guard !articles.isEmpty else {
            return nil
        }

        let bodyText = "The articles most-viewed since your edit:"
        let items = articles.map { article in
            ListItem(title: article.title, subtitle: article.viewCount.map { "\(formatted($0)) views" } ?? "")
        }
        return listSlide(
            id: "mostViewedEdits",
            artboard: "frame18",
            stateMachine: "frame18-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    // MARK: - Topics

    /// The topic in the app's topic list for a topic name.
    /// TODO: Confirm the saved format once real data is used. This only matches names like "history".
    private func articleTopic(named name: String) -> WMFArticleTopic? {
        WMFArticleTopic(rawValue: name)
    }

    /// The translated topic name, or the name as given when it does not match a topic in the app's list.
    private func topicDisplayName(_ name: String) -> String {
        articleTopic(named: name)?.displayName ?? name
    }

    /// The closing line for the top topic slide, from the topics copy sheet.
    private func topicLine(for topic: WMFArticleTopic) -> String {
        switch topic {
        case .architecture: return "You spent the year appreciating things that were built to last."
        case .visualArts: return "You gravitated toward the beautiful, the bold, and the occasionally baffling."
        case .comicsAndAnime: return "Panel by panel, you went deep on the worlds of comics and anime."
        case .entertainment: return "You couldn't stay away from the world of entertainment this year."
        case .fashion: return "You clicked into the world of style more than most."
        case .books: return "Your reading had a literary streak this year."
        case .music: return "Your curiosity had a soundtrack this year."
        case .performingArts: return "You were drawn to the stage, in one form or another."
        case .sports: return "You kept score on the world of sports this year."
        case .films: return "Your reading doubled as a watchlist this year."
        case .videoGames: return "You leveled up your knowledge of video games."
        case .biography: return "You spent the year getting to know other people's stories."
        case .women: return "You spent the year getting to know other people's stories."
        case .businessAndEconomics: return "You kept an eye on how the world does business."
        case .education: return "Learning about learning was kind of your thing this year."
        case .foodAndDrink: return "Your curiosity had a bit of an appetite this year."
        case .history: return "You're clearly fascinated by the past."
        case .militaryAndWarfare: return "You dug into the history of conflict and defense."
        case .philosophyAndReligion: return "You spent time with the big questions this year."
        case .politicsAndGovernment: return "You kept tabs on how the world is run."
        case .society: return "You were curious about the way people live and organize."
        case .transportation: return "You looked into how the world gets from place to place."
        case .biology: return "You explored the science of living things."
        case .chemistry: return "You mixed a little chemistry into your reading this year."
        case .internetCulture: return "You spent real time understanding the tech behind your screen."
        case .geographical: return "You kept your reading grounded, literally."
        case .engineering: return "You liked learning how things are built and how they work."
        case .stem: return "Your curiosity ran wide across the sciences."
        case .mathematics: return "You gave numbers their due this year."
        case .medicineAndHealth: return "You spent time learning how the body works."
        case .physics: return "You looked into the rules that run the universe."
        case .technology: return "You kept up with how things are changing."
        case .africa: return "Your reading took you across Africa this year."
        case .asia: return "Your reading took you across Asia this year."
        case .centralAmerica: return "Your reading took you through Central America this year."
        case .europe: return "Your reading took you across Europe this year."
        case .northAmerica: return "Your reading kept you close to home in North America (or explored it from afar)."
        case .oceania: return "Your reading carried you out to Oceania this year."
        case .southAmerica: return "Your reading took you across South America this year."
        }
    }

    // MARK: - Formatting

    private var year: Int {
        WMFYearInReviewDataController.targetYear
    }

    private func formatted(_ number: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }

    /// `percent` is out of 100, so 0.01 shows as 0.01%.
    private func formattedPercent(_ percent: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: percent / 100)) ?? ""
    }

    private func monthName(_ month: Int, calendar: Calendar = .current) -> String {
        let symbols = calendar.standaloneMonthSymbols
        let index = month - 1
        guard symbols.indices.contains(index) else {
            return ""
        }
        return symbols[index]
    }

    /// The hour in the reader's clock style, such as "7 PM" or "19".
    private func hourName(_ hour: Int, calendar: Calendar = .current) -> String {
        guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("j")
        return formatter.string(from: date)
    }

    private func formattedMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter.string(from: date)
    }

    private func formattedDateRange(from start: Date, to end: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateTemplate = "MMMMd"
        return formatter.string(from: start, to: end)
    }

    private func listAccessibilityLabel(heading: String, items: [ListItem]) -> String {
        let itemLabels = items.map { item in
            item.subtitle.isEmpty ? "\(item.title)." : "\(item.title), \(item.subtitle)."
        }
        return ([heading] + itemLabels).joined(separator: " ")
    }

    // MARK: - Templates

    /// Text fields on the `DataTemplate` view model in the templates file. `coverTitle` is only
    /// used by the cover.
    private enum TemplateTextPath {
        static let headline = WMFRiveText(path: "headline")
        static let data = WMFRiveText(path: "data")
        static let bodyCopy = WMFRiveText(path: "bodyCopy")
    }

    /// Text fields on the `List` view model in the templates file. The icon fields are not text,
    /// so they are not set here.
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

    /// One row on a list slide.
    private struct ListItem {
        let title: String
        let subtitle: String
    }

    /// A slide from the templates file. Pass `nil` for `data` on the empty versions, which do not
    /// show a number.
    private func templateSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String,
        data: String?,
        body: String,
        accessibilityLabel: String,
        showsShareButton: Bool = true
    ) -> WMFYearInReviewSlideViewModel {
        var text: [WMFRiveText: String] = [
            TemplateTextPath.headline: headline,
            TemplateTextPath.bodyCopy: body
        ]
        if let data {
            text[TemplateTextPath.data] = data
        }

        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            showsShareButton: showsShareButton,
            contentStyle: .dark
        )
    }

    /// A list slide from the templates file. Frames use `headline`, `bodyText` or both, so pass
    /// `nil` for any it does not use. Pass no items on the empty versions. The file has room for
    /// three items.
    private func listSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String?,
        bodyText: String?,
        items: [ListItem],
        accessibilityLabel: String,
        showsShareButton: Bool = true
    ) -> WMFYearInReviewSlideViewModel {
        var text: [WMFRiveText: String] = [:]
        if let headline {
            text[ListTextPath.headline] = headline
        }
        if let bodyText {
            text[ListTextPath.bodyText] = bodyText
        }
        for (number, item) in zip(1...3, items) {
            text[ListTextPath.articleTitle(number)] = item.title
            text[ListTextPath.subTitle(number)] = item.subtitle
        }

        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            showsShareButton: showsShareButton,
            contentStyle: .dark
        )
    }

    /// The file with the cover and the frame templates.
    private let templatesResourceName = "all_templates"
}
