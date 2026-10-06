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
            contentStyle: .dark,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.copyFits(headline: DataTextPath.headline, bodyText: DataTextPath.bodyCopy) + (data == nil ? [] : [Self.dataNumberFit])
        )
    }

    // MARK: - Text size

    /// The headline and the body copy grow, so long copy can push the content past the bottom of the
    /// slide. Over these line counts, make both smaller by the same scale, to at most 75%. The width
    /// is smaller than the text boxes on any frame, so the line counts are safe.
    private static func copyFits(headline: WMFRiveText, bodyText: WMFRiveText) -> [WMFRiveTextFit] {
        [
            WMFRiveTextFit(
                text: headline,
                fontAssetName: "SerifFont",
                maximumWidth: copyWidth,
                maximumLines: 3,
                minimumScale: 0.75,
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
                minimumScale: 0.75,
                group: "copy",
                globalViewModelName: "GlobalProperties",
                fontSize: WMFRiveNumber(path: "bodyCopyFontSize"),
                lineHeight: WMFRiveNumber(path: "bodyCopyLineHeight")
            )
        ]
    }

    /// In artboard units. The headline and body boxes are about 296 to 320 wide.
    private static let copyWidth = 290.0

    /// Each template in the file sets this flag for the contrast of the controls above it. The style
    /// that the factory passes shows only until the slide loads.
    private static let lightContentFlag = WMFRiveBool(path: "isUIWhite")

    /// The file with the frame templates.
    private let templatesResourceName = "all_templates"
}
