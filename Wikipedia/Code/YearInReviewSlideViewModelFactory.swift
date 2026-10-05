import CocoaLumberjackSwift
import Foundation
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Makes the content that the Year in Review view model is built from.
struct YearInReviewSlideViewModelFactory {

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

    /// Shows all the frames in the templates file, from the cover to the end slide.
    /// Only the total articles slide and the articles visited multiple times slide have real data so far.
    /// The other slides show mock data until their tickets give them real data.
    /// A data-rich user sees their data, but a slide without enough data shows its empty version.
    /// - Parameter forcesAllEmptyStates: shows the empty version of each personalized slide. Only the developer settings use it.
    func makeSlides(userDataState: WMFYearInReviewDataController.YiRUserDataState, forcesAllEmptyStates: Bool = false) -> [WMFYearInReviewSlideViewModel] {
        let showsEmptyStates: Bool
        let totalArticles: WMFYearInReviewSlideViewModel
        let rereadArticles: WMFYearInReviewSlideViewModel
        switch userDataState {
        case .lowData:
            // TODO: Show the collective slides when the templates file has them. Until then, a
            // low-data user sees the empty version of each personalized slide, so Year in Review
            // never opens with no slides.
            showsEmptyStates = true
            totalArticles = totalArticlesEmptySlide()
            rereadArticles = rereadArticlesEmptySlide()
        case .dataRich where forcesAllEmptyStates:
            showsEmptyStates = true
            totalArticles = totalArticlesEmptySlide()
            rereadArticles = rereadArticlesEmptySlide()
        case .dataRich:
            // No stored data means no qualifying articles, so show the empty states, never zero slides.
            let config = try? WMFYearInReviewDataController().config
            let readCount = storedReadCount() ?? 0
            showsEmptyStates = false
            totalArticles = totalArticlesSlide(
                readCount: readCount,
                topReadPercentage: config?.topReadPercentage(forReadCount: readCount),
                averageReadCount: config?.averageArticlesReadPerYear
            )
            rereadArticles = rereadArticlesSlide(storedRereadArticles() ?? [])
        }

        return [mockCoverSlide(), totalArticles]
            + mockSlidesBeforeRereadArticles(showsEmptyStates: showsEmptyStates)
            + [rereadArticles]
            + mockSlidesAfterRereadArticles(showsEmptyStates: showsEmptyStates)
            + [mockEndSlide()]
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

        let headline = WMFLocalizedString("year-in-review-2026-total-articles-title", value: "Your total article count:", comment: "Title of the Year in Review slide that shows the number of unique articles the reader read this year. The number follows it.")
        let count = NumberFormatter.localizedString(from: NSNumber(value: readCount), number: .decimal)
        let bodyText: String
        if let topReadPercentage, let averageReadCount {
            let format = WMFLocalizedString("year-in-review-2026-total-articles-top-percent-subtitle", value: "That puts you in the top %1$@ of Wikipedia readers globally. The average person reads {{PLURAL:%2$d|%2$d article|%2$d articles}} a year.", comment: "Subtitle of the Year in Review slide that shows the number of articles the reader read this year, for readers in the top 50% or better. %1$@ is replaced with a percentage, for example \"50%\". %2$d is replaced with the number of articles the average person reads in a year.")
            bodyText = String.localizedStringWithFormat(format, percentString(topReadPercentage), averageReadCount)
        } else {
            bodyText = WMFLocalizedString("year-in-review-2026-total-articles-subtitle", value: "You've been exploring all year. Every article added something to what you know.", comment: "Subtitle of the Year in Review slide that shows the number of articles the reader read this year, for readers below the top 50%.")
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
        let headline = WMFLocalizedString("year-in-review-2026-total-articles-empty-title", value: "You have millions of articles to discover", comment: "Title of the Year in Review slide shown when the reader read fewer than three articles this year, or when the reader does not have enough data for a personalized Year in Review.")
        let bodyText = WMFLocalizedString("year-in-review-2026-total-articles-empty-subtitle", value: "Just wait until you find out all there is to learn on Wikipedia.", comment: "Subtitle of the Year in Review slide shown when the reader read fewer than three articles this year, or when the reader does not have enough data for a personalized Year in Review.")
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

    // MARK: - Articles visited multiple times

    private struct RereadArticle {
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
    private func rereadArticlesSlide(_ articles: [RereadArticle]) -> WMFYearInReviewSlideViewModel {
        guard articles.count >= WMFYearInReviewTopArticlesSlideData.minimumArticleCount else {
            return rereadArticlesEmptySlide()
        }

        let bodyText = WMFLocalizedString("year-in-review-2026-reread-articles-title", value: "Some articles in your rotation:", comment: "Title of the Year in Review slide that lists up to three articles the reader visited two or more times this year. The list of articles follows it.")
        let visitCountFormat = WMFLocalizedString("year-in-review-2026-reread-articles-visit-count", value: "{{PLURAL:%1$d|%1$d visit|%1$d visits}}", comment: "Shown under each article on the Year in Review slide of articles visited multiple times. %1$d is replaced with the number of times the reader visited the article this year.")
        let shownArticles = Array(articles.prefix(3))
        let items = shownArticles.map { article in
            ListItem(title: article.title, subtitle: String.localizedStringWithFormat(visitCountFormat, article.visitCount))
        }
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        for (index, article) in shownArticles.enumerated() {
            guard let project = article.project else { continue }
            thumbnails[WMFRiveImage(path: "icon\(index + 1)")] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: project, title: article.title)
        }
        // A row that is not written keeps the copy inside the .riv ("initial value"), so clear the unused rows.
        let emptyRows = Array(repeating: ListItem(title: "", subtitle: ""), count: 3 - items.count)
        return listSlide(
            id: "rereadArticles",
            artboard: "frame12",
            stateMachine: "frame12-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items + emptyRows,
            articleThumbnails: thumbnails,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
        )
    }

    private func rereadArticlesEmptySlide() -> WMFYearInReviewSlideViewModel {
        let headline = WMFLocalizedString("year-in-review-2026-reread-articles-empty-title", value: "You're not a re-reader", comment: "Title of the Year in Review slide shown when the reader did not visit at least two articles two or more times each, or when the reader does not have enough data for a personalized Year in Review.")
        let bodyText = WMFLocalizedString("year-in-review-2026-reread-articles-empty-subtitle", value: "So much for looking at an article twice. You prefer novelty and falling down new rabbit holes.", comment: "Subtitle of the Year in Review slide shown when the reader did not visit at least two articles two or more times each, or when the reader does not have enough data for a personalized Year in Review.")
        return listSlide(
            id: "rereadArticlesEmpty",
            artboard: "frame12-empty",
            stateMachine: "frame12-empty-statemachine",
            headline: headline,
            bodyText: bodyText,
            items: [],
            accessibilityLabel: "\(headline). \(bodyText)"
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

    /// A list slide from the templates file. Pass `nil` for a text field that the frame does not
    /// use. The file has room for three items.
    private func listSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String?,
        bodyText: String?,
        items: [ListItem],
        articleThumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:],
        accessibilityLabel: String
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
            articleThumbnails: articleThumbnails,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark
        )
    }

    // MARK: - Data slides

    /// Text fields on the `DataTemplate` view model in the templates file.
    private enum DataTextPath {
        static let headline = WMFRiveText(path: "headline")
        static let data = WMFRiveText(path: "data")
        static let bodyCopy = WMFRiveText(path: "bodyCopy")
    }

    /// A slide from the templates file that shows one number. Pass `nil` for a text field that the
    /// frame does not use.
    private func dataSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        headline: String,
        data: String?,
        bodyText: String,
        accessibilityLabel: String
    ) -> WMFYearInReviewSlideViewModel {
        var text: [WMFRiveText: String] = [
            DataTextPath.headline: headline,
            DataTextPath.bodyCopy: bodyText
        ]
        if let data {
            text[DataTextPath.data] = data
        }

        return WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine),
            text: text,
            localizedStrings: .init(accessibilityLabel: accessibilityLabel),
            contentStyle: .dark
        )
    }

    /// The file with the frame templates.
    private let templatesResourceName = "all_templates"
}

// MARK: - Mock slides

// TODO: Replace each mock slide with real data in its own ticket. The copy is not localized on
// purpose: it is placeholder copy from the templates file, and the final copy can change.
extension YearInReviewSlideViewModelFactory {

    /// The articles on the mock list slides. They are real English Wikipedia articles, so the
    /// thumbnails load.
    private static let mockArticles = [
        "Pamela Anderson",
        "Pamukkale",
        "Catherine, Princess of Wales"
    ]

    private static let mockProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    /// Frames 2 to 10. Frame 11 has no content in the templates file, so it is not shown.
    private func mockSlidesBeforeRereadArticles(showsEmptyStates: Bool) -> [WMFYearInReviewSlideViewModel] {
        [
            mockDataSlide(
                frame: "frame2",
                headline: WMFLocalizedString("year-in-review-2026-mock-days-visited-title", value: "Days you visited Wikipedia in 2026:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                data: "55",
                bodyCopy: WMFLocalizedString("year-in-review-2026-mock-days-visited-subtitle", value: "Your activity peaked in December, when you read on 20 different days.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
            ),
            mockDataSlide(
                frame: "frame3",
                headline: WMFLocalizedString("year-in-review-2026-mock-minutes-title", value: "Total minutes spent reading:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                data: "924",
                bodyCopy: WMFLocalizedString("year-in-review-2026-mock-minutes-subtitle", value: "That's longer than a full night's sleep. Time flies when you're falling down a rabbit hole.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
            ),
            showsEmptyStates
                ? mockDataSlide(
                    frame: "frame4-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-streak-empty-title", value: "0 reading streaks... yet", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: nil,
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-streak-empty-subtitle", value: "It's not a streak until you've done it for 3 consecutive days. Why not start now?", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                )
                : mockDataSlide(
                    frame: "frame4",
                    headline: WMFLocalizedString("year-in-review-2026-mock-streak-title", value: "Days in your longest reading streak", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: "14",
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-streak-subtitle", value: "From March 4 to March 17, you really got into the groove of reading every day.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                ),
            showsEmptyStates
                ? mockDataSlide(
                    frame: "frame5-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-time-empty-title", value: "You read basically whenever", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: nil,
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-time-empty-subtitle", value: "There's no set day or time when to decide to explore the pages of Wikipedia.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                )
                : mockDataSlide(
                    frame: "frame5",
                    headline: WMFLocalizedString("year-in-review-2026-mock-time-title", value: "Favorite time to explore:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: WMFLocalizedString("year-in-review-2026-mock-time-data", value: "TUESDAY EVENINGS", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-time-subtitle", value: "50% of your exploring occurred during this time and on this day of the week. Coincidence or...not?", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                ),
            showsEmptyStates
                ? mockDataSlide(
                    frame: "frame6-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-topic-empty-title", value: "Your #1 topic of 2026 is... all of them", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: nil,
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-topic-empty-subtitle", value: "With so many interests, there's no one topic that defined your reading habits.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                )
                : mockDataSlide(
                    frame: "frame6",
                    headline: WMFLocalizedString("year-in-review-2026-mock-topic-title", value: "Your top topic of 2026:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: WMFLocalizedString("year-in-review-2026-mock-topic-data", value: "HISTORY", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-topic-subtitle", value: "From Battle of Gettysburg to Xia Dynasty, 23 of your articles were tied to this theme. You're clearly fascinated by the past.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                ),
            mockListSlide(
                frame: "frame7",
                headline: "",
                bodyText: WMFLocalizedString("year-in-review-2026-mock-runners-up-title", value: "And your runners-up for 2026:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                items: [
                    ListItem(title: WMFLocalizedString("year-in-review-2026-mock-runners-up-1", value: "Central America", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."), subtitle: WMFLocalizedString("year-in-review-2026-mock-runners-up-1-count", value: "14 articles", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: WMFLocalizedString("year-in-review-2026-mock-runners-up-2", value: "Visual art", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."), subtitle: WMFLocalizedString("year-in-review-2026-mock-runners-up-2-count", value: "12 articles", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: WMFLocalizedString("year-in-review-2026-mock-runners-up-3", value: "Politics and government", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."), subtitle: WMFLocalizedString("year-in-review-2026-mock-runners-up-3-count", value: "8 articles", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."))
                ],
                hasThumbnails: false
            ),
            mockDataSlide(
                frame: "frame8",
                headline: WMFLocalizedString("year-in-review-2026-mock-biggest-day-title", value: "Biggest reading day:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                data: WMFLocalizedString("year-in-review-2026-mock-biggest-day-data", value: "MARCH 7", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                bodyCopy: WMFLocalizedString("year-in-review-2026-mock-biggest-day-subtitle", value: "You spent a total of 43 minutes on Wikipedia. How's that for being productive?", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
            ),
            mockListSlide(
                frame: "frame9",
                headline: WMFLocalizedString("year-in-review-2026-mock-taste-title", value: "This is just a taste of some of the articles:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                bodyText: "",
                items: [
                    ListItem(title: Self.mockArticles[0], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-1", value: "American supermodel", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: Self.mockArticles[1], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-2", value: "Natural site in Denizli Province in southwestern Turkey", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: Self.mockArticles[2], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-3", value: "A member of the British royal family.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."))
                ],
                hasThumbnails: true
            ),
            mockInteractionSlide()
        ]
    }

    /// Frames 13 to 18.
    private func mockSlidesAfterRereadArticles(showsEmptyStates: Bool) -> [WMFYearInReviewSlideViewModel] {
        [
            mockDataSlide(
                frame: "frame13",
                headline: WMFLocalizedString("year-in-review-2026-mock-niche-title", value: "Talk about having niche interests, like:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                data: WMFLocalizedString("year-in-review-2026-mock-niche-data", value: "MEDIEVAL SIEGE ENGINES", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                bodyCopy: WMFLocalizedString("year-in-review-2026-mock-niche-subtitle", value: "For one reason or another, when it came to this category, you went all in!", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
            ),
            showsEmptyStates
                ? mockListSlide(
                    frame: "frame14-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-map-empty-title", value: "Your reading took you all over the map", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    bodyText: WMFLocalizedString("year-in-review-2026-mock-map-empty-subtitle", value: "Your articles came from so many places that no single one stands out.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    items: [],
                    hasThumbnails: false
                )
                : mockListSlide(
                    frame: "frame14",
                    headline: "",
                    bodyText: WMFLocalizedString("year-in-review-2026-mock-map-title", value: "Your reading practically took you to:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    items: [ListItem(title: WMFLocalizedString("year-in-review-2026-mock-map-place", value: "France", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."), subtitle: WMFLocalizedString("year-in-review-2026-mock-map-place-count", value: "Based on 12 articles", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."))],
                    hasThumbnails: false
                ),
            showsEmptyStates
                ? mockListSlide(
                    frame: "frame15-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-saved-empty-title", value: "You have 0 articles saved.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    bodyText: WMFLocalizedString("year-in-review-2026-mock-saved-empty-subtitle", value: "You currently have 0 articles saved. Look for the bookmark icon on an article, so you can read up on whatever... later.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    items: [],
                    hasThumbnails: false
                )
                : mockListSlide(
                    frame: "frame15",
                    headline: "",
                    bodyText: WMFLocalizedString("year-in-review-2026-mock-saved-title", value: "Articles you saved for later: 26", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    items: [
                        ListItem(title: Self.mockArticles[0], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-1", value: "American supermodel", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                        ListItem(title: Self.mockArticles[1], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-2", value: "Natural site in Denizli Province in southwestern Turkey", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                        ListItem(title: Self.mockArticles[2], subtitle: WMFLocalizedString("year-in-review-2026-mock-description-3", value: "A member of the British royal family.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."))
                    ],
                    hasThumbnails: true
                ),
            showsEmptyStates
                ? mockDataSlide(
                    frame: "frame16-empty",
                    headline: WMFLocalizedString("year-in-review-2026-mock-edits-empty-title", value: "You've made 0 edits so far", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: nil,
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-edits-empty-subtitle", value: "You haven't made any edits yet, but it's easy to learn how. Now's a good time to join the community that builds Wikipedia.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                )
                : mockDataSlide(
                    frame: "frame16",
                    headline: WMFLocalizedString("year-in-review-2026-mock-edits-title", value: "Edits you made:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                    data: "357",
                    bodyCopy: WMFLocalizedString("year-in-review-2026-mock-edits-subtitle", value: "Whether you contribute to Wikipedia, Wikimedia Commons, or Wikidata, thank you for improving everyone's access to human knowledge.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
                ),
            mockDataSlide(
                frame: "frame17",
                headline: WMFLocalizedString("year-in-review-2026-mock-edit-views-title", value: "Views your edits received:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                data: "14,791",
                bodyCopy: WMFLocalizedString("year-in-review-2026-mock-edit-views-subtitle", value: "In 2026, readers from around the world saw the changes you made.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
            ),
            mockListSlide(
                frame: "frame18",
                headline: "",
                bodyText: WMFLocalizedString("year-in-review-2026-mock-most-viewed-title", value: "The articles most-viewed since your edit:", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
                items: [
                    ListItem(title: Self.mockArticles[0], subtitle: WMFLocalizedString("year-in-review-2026-mock-most-viewed-1-count", value: "200 views", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: Self.mockArticles[1], subtitle: WMFLocalizedString("year-in-review-2026-mock-most-viewed-2-count", value: "150 views", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")),
                    ListItem(title: Self.mockArticles[2], subtitle: WMFLocalizedString("year-in-review-2026-mock-most-viewed-3-count", value: "50 views", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."))
                ],
                hasThumbnails: true
            )
        ]
    }

    /// Frame 10 asks which of two articles the reader read the longest, then shows the result.
    /// It uses the `Interaction` view model, not `List`.
    private func mockInteractionSlide() -> WMFYearInReviewSlideViewModel {
        let headline = WMFLocalizedString("year-in-review-2026-mock-longest-read-title", value: "What was the article you read the longest?", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        let firstSubtitle = WMFLocalizedString("year-in-review-2026-mock-description-2", value: "Natural site in Denizli Province in southwestern Turkey", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        let secondSubtitle = WMFLocalizedString("year-in-review-2026-mock-description-1", value: "American supermodel", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        let resultSubtitle = WMFLocalizedString("year-in-review-2026-mock-longest-read-result", value: "You read it for 12 minutes", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        let first = Self.mockArticles[1]
        let second = Self.mockArticles[0]
        return WMFYearInReviewSlideViewModel(
            id: "mock-frame10",
            loggingID: "mock-frame10",
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: "frame10", stateMachineName: "frame10-statemachine"),
            text: [
                WMFRiveText(path: "headline"): headline,
                WMFRiveText(path: "articleTitle1"): first,
                WMFRiveText(path: "subTitle1"): firstSubtitle,
                WMFRiveText(path: "articleTitle2"): second,
                WMFRiveText(path: "subTitle2"): secondSubtitle,
                WMFRiveText(path: "resultTitle"): first,
                WMFRiveText(path: "resultSubTitle"): resultSubtitle
            ],
            articleThumbnails: [
                WMFRiveImage(path: "thumbnail1"): .init(project: Self.mockProject, title: first),
                WMFRiveImage(path: "thumbnail2"): .init(project: Self.mockProject, title: second),
                WMFRiveImage(path: "resultThumbnail"): .init(project: Self.mockProject, title: first)
            ],
            localizedStrings: .init(accessibilityLabel: "\(headline) \(first), \(firstSubtitle). \(second), \(secondSubtitle). \(first), \(resultSubtitle)."),
            contentStyle: .dark
        )
    }

    /// The first slide, in place of the announcement.
    private func mockCoverSlide() -> WMFYearInReviewSlideViewModel {
        mockTitleSlide(
            frame: "cover",
            title: WMFLocalizedString("year-in-review-2026-mock-cover-title", value: "YOUR WIKIPEDIA YEAR IN REVIEW IS HERE", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
            bodyCopy: WMFLocalizedString("year-in-review-2026-mock-cover-subtitle", value: "Thanks for spending 55 days on your trusty Wikipedia App in 2026.", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        )
    }

    private func mockEndSlide() -> WMFYearInReviewSlideViewModel {
        mockTitleSlide(
            frame: "end",
            title: WMFLocalizedString("year-in-review-2026-mock-end-title", value: "THANK YOU!", comment: "Mock copy for a Year in Review slide. Only for testing, not for release."),
            bodyCopy: WMFLocalizedString("year-in-review-2026-mock-end-subtitle", value: "As an editor, your contributions keep Wikipedia ad-free, trustworthy, and available to everyone. We can't thank you enough for supporting Wikipedia!", comment: "Mock copy for a Year in Review slide. Only for testing, not for release.")
        )
    }

    /// The cover and the end frames use `coverTitle` in place of `headline` and `data`.
    private func mockTitleSlide(frame: String, title: String, bodyCopy: String) -> WMFYearInReviewSlideViewModel {
        WMFYearInReviewSlideViewModel(
            id: "mock-\(frame)",
            loggingID: "mock-\(frame)",
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: frame, stateMachineName: "\(frame)-statemachine"),
            text: [
                WMFRiveText(path: "coverTitle"): title,
                DataTextPath.headline: "",
                DataTextPath.data: "",
                DataTextPath.bodyCopy: bodyCopy
            ],
            localizedStrings: .init(accessibilityLabel: "\(title). \(bodyCopy)"),
            contentStyle: .dark
        )
    }

    private func mockDataSlide(frame: String, headline: String, data: String?, bodyCopy: String) -> WMFYearInReviewSlideViewModel {
        dataSlide(
            id: "mock-\(frame)",
            artboard: frame,
            stateMachine: "\(frame)-statemachine",
            headline: headline,
            data: data,
            bodyText: bodyCopy,
            accessibilityLabel: [headline, data, bodyCopy].compactMap { $0 }.joined(separator: " ")
        )
    }

    /// Pass `""` for a text field that the frame does not use, so the copy in the .riv does not show.
    /// Rows that are not given are written as empty rows, for the same reason.
    private func mockListSlide(frame: String, headline: String, bodyText: String, items: [ListItem], hasThumbnails: Bool) -> WMFYearInReviewSlideViewModel {
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        if hasThumbnails {
            for (index, item) in items.enumerated() where !item.title.isEmpty {
                thumbnails[WMFRiveImage(path: "icon\(index + 1)")] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: Self.mockProject, title: item.title)
            }
        }
        let heading = [headline, bodyText].filter { !$0.isEmpty }.joined(separator: ". ")
        let accessibilityLabel = listAccessibilityLabel(heading: heading, items: items.filter { !$0.title.isEmpty })
        return listSlide(
            id: "mock-\(frame)",
            artboard: frame,
            stateMachine: "\(frame)-statemachine",
            headline: headline,
            bodyText: bodyText,
            items: items + Array(repeating: ListItem(title: "", subtitle: ""), count: max(0, 3 - items.count)),
            articleThumbnails: thumbnails,
            accessibilityLabel: accessibilityLabel
        )
    }
}
