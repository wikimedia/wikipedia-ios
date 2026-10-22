import CocoaLumberjackSwift
import Foundation
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Makes the content that the Year in Review view model is built from.
struct YearInReviewSlideViewModelFactory {

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

    /// Only the total articles, days visited, articles visited multiple times and topic slides have real data so far.
    /// A data-rich user sees their data, but a slide without enough data shows its empty version.
    /// The days visited slide has no empty version, so it does not show without enough data.
    /// - Parameter forcesAllEmptyStates: shows the empty version of each personalized slide. Only the developer settings use it.
    func makeSlides(userDataState: WMFYearInReviewDataController.YiRUserDataState, forcesAllEmptyStates: Bool = false) -> [WMFYearInReviewSlideViewModel] {
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
            var slides = [
                totalArticlesSlide(
                    readCount: readCount,
                    topReadPercentage: config?.topReadPercentage(forReadCount: readCount),
                    averageReadCount: config?.averageArticlesReadPerYear
                )
            ]
            if let daysVisited = daysVisitedSlide(storedDaysVisited()) {
                slides.append(daysVisited)
            }
            slides.append(rereadArticlesSlide(storedRereadArticles() ?? []))
            return slides + topicSlides(storedTopTopics())
        }
    }

    private func personalizedEmptySlides() -> [WMFYearInReviewSlideViewModel] {
        [totalArticlesEmptySlide(), rereadArticlesEmptySlide(), topTopicEmptySlide()]
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
            stateMachine: "frame12-statemachine",
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
            stateMachine: "frame12-empty-statemachine",
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
            // The templates file shares the frame9 state machine with frame7.
            stateMachine: "frame9-statemachine",
            headline: nil,
            bodyText: bodyText,
            items: items,
            images: images,
            accessibilityLabel: listAccessibilityLabel(heading: bodyText, items: items)
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
