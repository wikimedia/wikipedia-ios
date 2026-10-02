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

    /// Only the articles visited multiple times slide has real data so far.
    func makeSlides() -> [WMFYearInReviewSlideViewModel] {
        // No stored data means no qualifying articles, so show the empty state, never zero slides.
        [rereadArticlesSlide(storedRereadArticles() ?? [])]
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
            let headline = WMFLocalizedString("year-in-review-2026-reread-articles-empty-title", value: "You're not a re-reader", comment: "Title of the Year in Review slide shown when the reader did not visit at least two articles two or more times each.")
            let bodyText = WMFLocalizedString("year-in-review-2026-reread-articles-empty-subtitle", value: "So much for looking at an article twice. You prefer novelty and falling down new rabbit holes.", comment: "Subtitle of the Year in Review slide shown when the reader did not visit at least two articles two or more times each.")
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

    /// The file with the frame templates.
    private let templatesResourceName = "all_templates"
}
