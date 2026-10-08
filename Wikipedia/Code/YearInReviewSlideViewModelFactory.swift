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

    /// Only the total articles slide and the articles visited multiple times slide have real data so far.
    /// A data-rich user sees their data, but a slide without enough data shows its empty version.
    /// - Parameter forcesAllEmptyStates: shows the empty version of each personalized slide. Only the developer settings use it.
    func makeSlides(userDataState: WMFYearInReviewDataController.YiRUserDataState, forcesAllEmptyStates: Bool = false) -> [WMFYearInReviewSlideViewModel] {
        // Developer setting: made-up slides for every template, for handing builds to design.
        let developerSettings = WMFDeveloperSettingsDataController.shared
        if developerSettings.forceYiREntryPoint2026, developerSettings.useYiRSampleData {
            return makeSampleSlides(language: developerSettings.yiRSampleLanguage, forcesAllEmptyStates: forcesAllEmptyStates)
        }

        switch userDataState {
        case .lowData:
            // TODO: Show the collective slides when the templates file has them. Until then, a
            // low-data user sees the empty version of each personalized slide, so Year in Review
            // never opens with no slides.
            return personalizedEmptySlides()
        case .dataRich where forcesAllEmptyStates:
            return personalizedEmptySlides()
        case .dataRich:
            // No stored data means no qualifying articles, so show the empty states, never zero slides.
            let config = try? WMFYearInReviewDataController().config
            let readCount = storedReadCount() ?? 0
            return [
                totalArticlesSlide(
                    readCount: readCount,
                    topReadPercentage: config?.topReadPercentage(forReadCount: readCount),
                    averageReadCount: config?.averageArticlesReadPerYear
                ),
                rereadArticlesSlide(storedRereadArticles() ?? [])
            ]
        }
    }

    private func personalizedEmptySlides() -> [WMFYearInReviewSlideViewModel] {
        [totalArticlesEmptySlide(), rereadArticlesEmptySlide()]
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
            artboard: "frame13",
            // The templates file names this state machine for the old slide number.
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
            artboard: "frame13-empty",
            // The templates file names this state machine for the old slide number.
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
    struct ListItem {
        let title: String
        let subtitle: String
    }

    func listAccessibilityLabel(heading: String, items: [ListItem]) -> String {
        let itemLabels = items.map { item in
            item.subtitle.isEmpty ? "\(item.title)." : "\(item.title), \(item.subtitle)."
        }
        return ([heading] + itemLabels).joined(separator: " ")
    }

    /// A list slide from the templates file. Pass `nil` for a text field that the frame does not
    /// use. The file has room for three items.
    func listSlide(
        id: String,
        artboard: String,
        stateMachine: String,
        viewModelInstanceName: String? = nil,
        headline: String?,
        bodyText: String?,
        items: [ListItem],
        numbers: [WMFRiveNumber: Double] = [:],
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
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: stateMachine, viewModelInstanceName: viewModelInstanceName),
            text: text,
            numbers: numbers,
            articleThumbnails: articleThumbnails,
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

    /// A slide from the templates file that shows one number. Pass `nil` for a text field that the
    /// frame does not use.
    func dataSlide(
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
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.copyFits(headline: DataTextPath.headline, bodyText: DataTextPath.bodyCopy) + (data == nil ? [] : [Self.dataNumberFit])
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
    static let lightContentFlag = WMFRiveBool(path: "isUIWhite")

    /// The file with the frame templates.
    let templatesResourceName = "all_templates"
}


// MARK: - Fake Data
/// Made-up Year in Review slides for the design build. Used only while the developer settings
/// "force entry point" and "use sample data" are both on. The slides go through the same helpers as
/// the real slides, so they get the same text fitting, thumbnails and light or dark controls.
///
/// English has every slide. Arabic and Japanese have one slide for each kind of template, which is
/// what the ticket asks for. The Arabic and Japanese text is placeholder text that a translator has
/// not checked.
///
/// The English copy comes from the Year in Review copy sheet. The numbers and the article lists are made up.
extension YearInReviewSlideViewModelFactory {

    /// - Parameter forcesAllEmptyStates: shows only the empty version of each slide that has one.
    func makeSampleSlides(language: WMFYiRSampleLanguage, forcesAllEmptyStates: Bool) -> [WMFYearInReviewSlideViewModel] {
        switch (language, forcesAllEmptyStates) {
        case (.english, false):
            return englishSlides.filter { Self.hasFrame19 || $0.animation?.artboardName != "frame19" }
        case (.english, true):
            return englishEmptySlides
        case (.arabic, false):
            return arabicSlides
        case (.arabic, true):
            return arabicEmptySlides
        case (.japanese, false):
            return japaneseSlides
        case (.japanese, true):
            return japaneseEmptySlides
        }
    }

    // MARK: - English

    private var englishSlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleCoverSlide(
                id: "cover",
                artboard: "cover",
                title: "Your Wikipedia Year in Review is here",
                body: "Thanks for spending 55 days on your trusty Wikipedia app in 2026."
            ),
            sampleDataSlide(
                artboard: "frame1",
                headline: "Your total article count:",
                data: "350",
                body: "That puts you in the top 50% of Wikipedia readers globally. The average person reads 335 articles a year."
            ),
            sampleDataSlide(
                artboard: "frame2",
                headline: "Days you visited Wikipedia in 2026:",
                data: "47",
                body: "Your activity peaked in December, when you read on 20 different days."
            ),
            sampleDataSlide(
                artboard: "frame3",
                headline: "Total minutes spent reading:",
                data: "924",
                body: "That's longer than a full night's sleep. Time flies when you're falling down a rabbit hole."
            ),
            sampleDataSlide(
                artboard: "frame4",
                headline: "Days in your longest reading streak:",
                data: "11",
                body: "From March 4–14, you really got into the groove of reading every day."
            ),
            sampleDataSlide(
                artboard: "frame5",
                headline: "Favorite time to explore:",
                data: "Evenings",
                body: "50% of your exploring occurred during this time of day. Coincidence or...not?"
            ),
            sampleDataSlide(
                artboard: "frame6",
                headline: "Your top topic of 2026:",
                data: "History",
                body: "From Battle of Gettysburg to Xia Dynasty, 23 of your articles were tied to this theme. You're clearly fascinated by the past."
            ),
            sampleListSlide(
                artboard: "frame7",
                bodyText: "And your runners-up for 2026:",
                items: frame7Items([
                    ListItem(title: "Central America", subtitle: "14 articles"),
                    ListItem(title: "Visual art", subtitle: "12 articles"),
                    ListItem(title: "Politics and government", subtitle: "8 articles")
                ]),
                setsRowCount: true
            ),
            sampleDataSlide(
                artboard: "frame8",
                headline: "Biggest reading day:",
                data: "March 7",
                body: "You spent a total of 43 minutes on Wikipedia. How's that for being productive?"
            ),
            sampleListSlide(
                artboard: Self.frame9LeftToRight,
                stateMachine: "frame9-statemachine",
                viewModelInstanceName: Self.frame9InstanceName,
                headline: "A taste of the articles you read:",
                items: [
                    ListItem(title: "Pamela Anderson", subtitle: "American supermodel"),
                    ListItem(title: "Pamukkale", subtitle: "Natural site in Denizli Province in southwestern Turkey"),
                    ListItem(title: "Dam", subtitle: "Barrier that holds back water")
                ],
                thumbnailTitles: ["Pamela Anderson", "Pamukkale", "Dam"],
                setsRowCount: true
            ),
            sampleListSlide(
                artboard: Self.rotationArtboard,
                stateMachine: Self.rotationStateMachine,
                bodyText: "Some articles in your rotation:",
                items: [
                    ListItem(title: "Dam", subtitle: "3 visits"),
                    ListItem(title: "Pamukkale", subtitle: "2 visits"),
                    ListItem(title: "Pamela Anderson", subtitle: "2 visits")
                ],
                thumbnailTitles: ["Dam", "Pamukkale", "Pamela Anderson"]
            ),
            sampleDataSlide(
                artboard: Self.nicheInterestArtboard,
                stateMachine: Self.nicheInterestStateMachine,
                headline: "Talk about having niche interests, like:",
                data: "Executed female serial killers",
                body: "For one reason or another, when it came to this category, you went all in!"
            ),
            sampleListSlide(
                artboard: "frame14",
                bodyText: "Your reading practically took you to:",
                items: [
                    ListItem(title: "Turkey", subtitle: "9 articles"),
                    ListItem(title: "Mexico", subtitle: "6 articles"),
                    ListItem(title: "Japan", subtitle: "4 articles")
                ],
                thumbnailTitles: ["Turkey", "Mexico", "Japan"]
            ),
            sampleListSlide(
                artboard: "frame15",
                bodyText: "Articles you saved for later: 26",
                items: [
                    ListItem(title: "Dam", subtitle: "Barrier that holds back water"),
                    ListItem(title: "Pamukkale", subtitle: "Natural site in Denizli Province in southwestern Turkey"),
                    ListItem(title: "Pamela Anderson", subtitle: "American supermodel")
                ],
                thumbnailTitles: ["Dam", "Pamukkale", "Pamela Anderson"]
            ),
            sampleDataSlide(
                artboard: "frame16",
                headline: "Edits you made:",
                data: "357",
                body: "Whether you contribute to Wikipedia, Wikimedia Commons, or Wikidata, thank you for improving everyone's access to human knowledge."
            ),
            sampleDataSlide(
                artboard: "frame17",
                headline: "Views your edits received:",
                data: "14,791",
                body: "In 2026, readers from around the world saw the changes you made."
            ),
            sampleListSlide(
                artboard: "frame18",
                bodyText: "The articles most-viewed since your edit:",
                items: [
                    ListItem(title: "Dam", subtitle: "1,204 views"),
                    ListItem(title: "Pamukkale", subtitle: "860 views"),
                    ListItem(title: "Pamela Anderson", subtitle: "517 views")
                ],
                thumbnailTitles: ["Dam", "Pamukkale", "Pamela Anderson"]
            ),
            sampleCoverSlide(
                id: "frame19",
                artboard: "frame19",
                title: "Thank you!",
                body: "As an editor and a donor, your contributions keep Wikipedia ad-free, trustworthy, and available to everyone. We can't thank you enough for supporting Wikipedia!"
            ),
            // Same artboard as the slide above. The logged-out text is different.
            sampleCoverSlide(
                id: "frame19-loggedOut",
                artboard: "frame19",
                title: "You matter.",
                body: "Wikipedia exists thanks to real people like you, contributing what they can to keep it thriving. If Wikipedia is valuable to you, please consider supporting it by donating or editing."
            )
        ]
    }

    private var englishEmptySlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleDataSlide(
                artboard: "frame1-empty",
                headline: "You have millions of articles to discover",
                data: nil,
                body: "Just wait until you find out all there is to learn on Wikipedia."
            ),
            sampleDataSlide(
                artboard: "frame4-empty",
                headline: "0 reading streaks... yet",
                data: nil,
                body: "It's not a streak until you've done it for 3 consecutive days. Why not start now?"
            ),
            sampleDataSlide(
                artboard: "frame5-empty",
                headline: "You read basically whenever",
                data: nil,
                body: "There's no set day or time when to decide to explore the pages of Wikipedia."
            ),
            sampleDataSlide(
                artboard: "frame6-empty",
                headline: "Your #1 topic of 2026 is... all of them",
                data: nil,
                body: "With so many interests, there's no one topic that defined your reading habits."
            ),
            sampleListSlide(
                artboard: Self.rotationEmptyArtboard,
                stateMachine: Self.rotationEmptyStateMachine,
                headline: "You're not a re-reader",
                bodyText: "So much for looking at an article twice. You prefer novelty and falling down new rabbit holes.",
                items: []
            ),
            sampleListSlide(
                artboard: "frame14-empty",
                headline: "Your reading took you all over the map",
                bodyText: "In 2026, you traveled all over Wikipedia. Check out the Places feature for ideas on where to go when you're on the go.",
                items: []
            ),
            sampleListSlide(
                artboard: "frame15-empty",
                headline: "You have 0 articles saved",
                bodyText: "You currently have 0 articles saved. Look for the bookmark icon on an article, so you can read up on whatever... later.",
                items: []
            ),
            sampleDataSlide(
                artboard: "frame16-empty",
                headline: "You've made 0 edits so far",
                data: nil,
                body: "You haven't made any edits yet, but it's easy to learn how. Now's a good time to join the community that builds Wikipedia."
            )
        ]
    }

    // MARK: - Arabic (placeholder text, right to left)

    private var arabicSlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleCoverSlide(
                id: "cover",
                artboard: "cover",
                title: "مراجعتك السنوية لويكيبيديا جاهزة",
                body: "شكرًا لقضاء 55 يومًا مع تطبيق ويكيبيديا في عام 2026."
            ),
            sampleDataSlide(
                artboard: "frame1",
                headline: "إجمالي عدد المقالات التي قرأتها:",
                data: "350",
                body: "أنت ضمن أعلى 50% من قراء ويكيبيديا حول العالم. يقرأ الشخص العادي 335 مقالة في السنة."
            ),
            sampleListSlide(
                artboard: "frame7",
                bodyText: "وأبرز اهتماماتك التالية لعام 2026:",
                items: frame7Items([
                    ListItem(title: "أمريكا الوسطى", subtitle: "14 مقالة"),
                    ListItem(title: "الفن التشكيلي", subtitle: "12 مقالة"),
                    ListItem(title: "السياسة والحكومة", subtitle: "8 مقالات")
                ]),
                setsRowCount: true
            ),
            sampleListSlide(
                artboard: Self.frame9RightToLeft,
                stateMachine: "frame9-statemachine",
                viewModelInstanceName: Self.frame9InstanceName,
                headline: "لمحة من المقالات التي قرأتها:",
                items: [
                    ListItem(title: "باميلا أندرسون", subtitle: "عارضة أزياء أمريكية"),
                    ListItem(title: "باموكالي", subtitle: "موقع طبيعي في محافظة دنيزلي جنوب غرب تركيا"),
                    ListItem(title: "سد", subtitle: "منشأة لحجز المياه")
                ],
                setsRowCount: true
            )
        ]
    }

    private var arabicEmptySlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleDataSlide(
                artboard: "frame1-empty",
                headline: "أمامك ملايين المقالات لاكتشافها",
                data: nil,
                body: "انتظر حتى تعرف كم يوجد على ويكيبيديا لتتعلمه."
            ),
            sampleListSlide(
                artboard: Self.rotationEmptyArtboard,
                stateMachine: Self.rotationEmptyStateMachine,
                headline: "لست من محبي إعادة القراءة",
                bodyText: "لا تحب النظر إلى المقالة مرتين. تفضّل التجديد والغوص في مواضيع جديدة.",
                items: []
            )
        ]
    }

    // MARK: - Japanese (placeholder text)

    private var japaneseSlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleCoverSlide(
                id: "cover",
                artboard: "cover",
                title: "あなたのWikipedia年間レビューが届きました",
                body: "2026年は55日間、Wikipediaアプリをご利用いただきありがとうございました。"
            ),
            sampleDataSlide(
                artboard: "frame1",
                headline: "読んだ記事の合計:",
                data: "350",
                body: "あなたは世界のWikipedia読者の上位50%に入っています。平均的な人は1年に335本の記事を読みます。"
            ),
            sampleListSlide(
                artboard: "frame7",
                bodyText: "2026年のその他の人気ジャンル:",
                items: frame7Items([
                    ListItem(title: "中央アメリカ", subtitle: "14件の記事"),
                    ListItem(title: "視覚芸術", subtitle: "12件の記事"),
                    ListItem(title: "政治・行政", subtitle: "8件の記事")
                ]),
                setsRowCount: true
            ),
            sampleListSlide(
                artboard: Self.frame9LeftToRight,
                stateMachine: "frame9-statemachine",
                viewModelInstanceName: Self.frame9InstanceName,
                headline: "読んだ記事のダイジェスト:",
                items: [
                    ListItem(title: "パメラ・アンダーソン", subtitle: "アメリカのモデル"),
                    ListItem(title: "パムッカレ", subtitle: "トルコ南西部デニズリ県の景勝地"),
                    ListItem(title: "ダム", subtitle: "水をせき止めるための構造物")
                ],
                setsRowCount: true
            )
        ]
    }

    private var japaneseEmptySlides: [WMFYearInReviewSlideViewModel] {
        [
            sampleDataSlide(
                artboard: "frame1-empty",
                headline: "発見できる記事が何百万もあります",
                data: nil,
                body: "Wikipediaで学べることの多さを、ぜひ体験してください。"
            ),
            sampleListSlide(
                artboard: Self.rotationEmptyArtboard,
                stateMachine: Self.rotationEmptyStateMachine,
                headline: "再読はしない派です",
                bodyText: "同じ記事を二度見ることはありません。新しい発見と、次々に広がる探検を好みます。",
                items: []
            )
        ]
    }

    // MARK: - Builders

    /// The two `frame9` artboards.
    private static let frame9LeftToRight = "frame9-leftToRight"
    private static let frame9RightToLeft = "frame9-rightToLeft"

    /// Both `frame9` artboards use the one view model instance called `frame9`.
    private static let frame9InstanceName = "frame9"

    /// In the current templates file, design renumbered three artboards but not their state machines,
    /// so the names do not match. Change these when design fixes the file.
    private static let nicheInterestArtboard = "frame12"
    private static let nicheInterestStateMachine = "frame13-statemachine"
    private static let rotationArtboard = "frame13"
    private static let rotationStateMachine = "frame12-statemachine"
    private static let rotationEmptyArtboard = "frame13-empty"
    private static let rotationEmptyStateMachine = "frame12-empty-statemachine"

    /// Off because the templates file in the app has no `frame19` artboard yet.
    private static let hasFrame19 = false

    /// Writes `numOfListItems` on frame 7 and frame 9. In a debug build, writing a property that is not
    /// in the file stops the app, so turn this off if the file in the app does not have it.
    private static let writesRowCount = true

    /// Frame 7 shows only as many rows as the developer setting asks for.
    /// `sampleListSlide` already writes `numOfListItems` from the item count and clears the unused rows.
    private func frame7Items(_ items: [ListItem]) -> [ListItem] {
        Array(items.prefix(WMFDeveloperSettingsDataController.shared.yiRSampleListItemCount))
    }

    /// An empty state has no number. `data` is still written, as an empty string, because a field that
    /// is not written shows the "initial value" text inside the .riv.
    private func sampleDataSlide(artboard: String, stateMachine: String? = nil, headline: String, data: String? = nil, body: String) -> WMFYearInReviewSlideViewModel {
        dataSlide(
            id: artboard,
            artboard: artboard,
            stateMachine: stateMachine ?? "\(artboard)-statemachine",
            headline: headline,
            data: data ?? "",
            bodyText: body,
            accessibilityLabel: [headline, data, body].compactMap { $0 }.joined(separator: " ")
        )
    }

    /// - Parameters:
    ///   - thumbnailTitles: English article titles for the row images. Used only when the app language is English, because the images come from that wiki.
    ///   - setsRowCount: sets `numOfListItems`, which frame 7 and frame 9 use to decide how many rows to show.
    private func sampleListSlide(
        artboard: String,
        stateMachine: String? = nil,
        viewModelInstanceName: String? = nil,
        headline: String? = nil,
        bodyText: String? = nil,
        items: [ListItem],
        thumbnailTitles: [String] = [],
        setsRowCount: Bool = false
    ) -> WMFYearInReviewSlideViewModel {
        // A row that is not written keeps the copy inside the .riv, so clear the unused rows.
        let emptyRows = Array(repeating: ListItem(title: "", subtitle: ""), count: max(0, 3 - items.count))
        let numbers: [WMFRiveNumber: Double] = setsRowCount && Self.writesRowCount ? [WMFRiveNumber(path: "numOfListItems"): Double(items.count)] : [:]

        return listSlide(
            id: artboard,
            artboard: artboard,
            stateMachine: stateMachine ?? "\(artboard)-statemachine",
            viewModelInstanceName: viewModelInstanceName,
            headline: headline,
            bodyText: bodyText,
            items: items + emptyRows,
            numbers: numbers,
            articleThumbnails: sampleThumbnails(titles: thumbnailTitles),
            accessibilityLabel: listAccessibilityLabel(heading: headline ?? bodyText ?? "", items: items)
        )
    }

    /// The cover and frame 19 use `coverTitle` and `bodyCopy`. Their title font path is not known to
    /// the app, so these slides have no text fitting.
    private func sampleCoverSlide(id: String, artboard: String, title: String, body: String) -> WMFYearInReviewSlideViewModel {
        WMFYearInReviewSlideViewModel(
            id: id,
            loggingID: id,
            animation: WMFRiveAnimation(resourceName: templatesResourceName, artboardName: artboard, stateMachineName: "\(artboard)-statemachine"),
            text: [
                WMFRiveText(path: "coverTitle"): title,
                WMFRiveText(path: "bodyCopy"): body
            ],
            localizedStrings: .init(accessibilityLabel: "\(title) \(body)"),
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag
        )
    }

    /// Thumbnails come from the English Wikipedia, so they are only set when the app language is English.
    /// Otherwise each row keeps the placeholder image in the .riv.
    private func sampleThumbnails(titles: [String]) -> [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] {
        guard let language = WMFDataEnvironment.current.primaryAppLanguage,
              language.languageCode.lowercased() == "en" else {
            return [:]
        }

        let project = WMFProject.wikipedia(language)
        var thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] = [:]
        for (index, title) in titles.prefix(3).enumerated() {
            thumbnails[WMFRiveImage(path: "icon\(index + 1)")] = WMFYearInReviewSlideViewModel.ArticleThumbnail(project: project, title: title)
        }
        return thumbnails
    }
}
