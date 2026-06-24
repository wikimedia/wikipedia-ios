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

    // MARK: - Title

    @Test
    func prefersDisplayTitleOverTitle() {
        let article = makeArticle(title: "Raw title", displayTitle: "<i>Display title</i>")
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        #expect(viewModel.title == "<i>Display title</i>")
    }

    @Test
    func fallsBackToTitleWhenDisplayTitleIsNil() {
        let article = makeArticle(title: "Raw title", displayTitle: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        #expect(viewModel.title == "Raw title")
    }

    // MARK: - Description

    @Test
    func descriptionIsNilWhenAbsent() {
        let article = makeArticle(description: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        #expect(viewModel.description == nil)
    }

    @Test
    func descriptionIsPopulatedWhenPresent() {
        let article = makeArticle(description: "A short description")
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        #expect(viewModel.description == "A short description")
    }

    // MARK: - Image

    @Test
    func imageIsNilBeforeLoad() {
        let article = makeArticle(thumbnailSource: "https://example.com/image.jpg")
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        #expect(viewModel.uiImage == nil)
    }

    @Test
    func loadIfNeededDoesNothingWhenNoThumbnail() {
        let article = makeArticle(thumbnailSource: nil)
        let viewModel = WMFInterestArticleCardViewModel(article: article)
        viewModel.loadIfNeeded()
        #expect(viewModel.uiImage == nil)
    }
}
