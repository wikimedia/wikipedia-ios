import Foundation
import Testing
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFInterestArticleCardViewModelTests {

    private func makeArticle(
        pageid: Int = 1,
        title: String = "Plain title",
        displayTitle: String? = nil,
        description: String? = nil,
        thumbnailSource: String? = nil
    ) -> WMFRandomArticle {
        let thumbnail = thumbnailSource.map { WMFRandomArticleThumbnail(source: $0, width: 100, height: 100) }
        return WMFRandomArticle(pageid: pageid, title: title, displayTitle: displayTitle, variantTitles: nil, description: description, extract: nil, thumbnail: thumbnail)
    }

    private var project: WMFProject {
        .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }

    // MARK: - Title

    @Test
    func displayTitlePrefersTheMarkedUpTitle() {
        let article = makeArticle(title: "Raw title", displayTitle: "<i>Display title</i>")
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.displayTitle == "<i>Display title</i>")
    }

    @Test
    func displayTitleFallsBackToTheCanonicalTitleWhenAbsent() {
        let article = makeArticle(title: "Raw_title", displayTitle: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.displayTitle == "Raw title")
    }

    /// The display title is markup for some articles (`<i>The Macomber Affair</i>` for a film), and
    /// `title` is what gets persisted as an interest and looked up for a summary — so it has to stay
    /// the canonical title, or the interest fetches nothing and its card shows no image.
    @Test
    func titleStaysCanonicalWhenTheDisplayTitleCarriesMarkup() {
        let article = makeArticle(title: "The_Macomber_Affair", displayTitle: "<i>The Macomber Affair</i>")
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.title == "The_Macomber_Affair")
    }

    @Test
    func searchResultTitleStaysCanonicalWhenTheDisplayTitleCarriesMarkup() {
        let result = WMFArticleSearchResult(pageID: 1, namespace: 0, title: "The Macomber Affair", displayTitle: "<i>The Macomber Affair</i>", description: nil, index: 1, thumbnail: nil)
        let viewModel = WMFInterestArticleCardViewModel(searchResult: result, project: project)
        #expect(viewModel.title == "The Macomber Affair")
        #expect(viewModel.displayTitle == "<i>The Macomber Affair</i>")
    }

    /// A saved interest and a fresh random article describe the same page with differently spaced
    /// titles, so the ids have to agree or the grid shows the article twice.
    @Test
    func idMatchesAcrossSources() {
        let fromArticle = WMFInterestArticleCardViewModel(article: makeArticle(title: "Marie Curie"), project: project)
        let fromInterest = WMFInterestArticleCardViewModel(pageInterest: WMFPageInterest(title: "Marie_Curie", timestamp: Date()), project: project)
        #expect(fromArticle.id == fromInterest.id)
    }

    // MARK: - Description

    @Test
    func descriptionIsNilWhenAbsent() {
        let article = makeArticle(description: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.description == nil)
    }

    @Test
    func descriptionIsPopulatedWhenPresent() {
        let article = makeArticle(description: "A short description")
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.description == "A short description")
    }

    // MARK: - Image

    @Test
    func imageIsNilBeforeLoad() {
        let article = makeArticle(thumbnailSource: "https://example.com/image.jpg")
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        #expect(viewModel.uiImage == nil)
    }

    @Test
    func loadIfNeededDoesNothingWhenNoThumbnail() {
        let article = makeArticle(thumbnailSource: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article, project: project)
        viewModel.loadIfNeeded()
        #expect(viewModel.uiImage == nil)
    }
}
