import CoreLocation
import Foundation
import Testing
@testable import Wikipedia
@testable import WMF
import WMFData

// Serialized: NSLocale.wmf_locale(for:) mutates an unsynchronized static cache.
@MainActor
@Suite(.serialized)
struct SearchResultsMapperTests {

    private let englishSiteURL = URL(string: "https://en.wikipedia.org")!

    @Test
    func mapsTheTitleURLAndThumbnail() throws {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])
        let thumbnailURL = URL(string: "https://upload.wikimedia.org/cat-120.jpg")!

        let result = try #require(mapper.searchResult(from: makeResult(title: "Cat", displayTitle: "Cat", displayTitleHTML: "<i>Cat</i>", thumbnailURL: thumbnailURL)))

        #expect(result.articleURL == englishSiteURL.wmf_URL(withTitle: "Cat"))
        #expect(result.pageTitle == "Cat")
        #expect(result.title == "Cat")
        #expect(result.titleHTML == "<i>Cat</i>")
        #expect(result.thumbnailURL == thumbnailURL)
        #expect(result.isArticle)
        #expect(!result.hasLocation)
        #expect(result.isSavable)
        #expect(!result.isSaved)
    }

    @Test
    func resultsWithCoordinatesHaveALocation() throws {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])
        let location = CLLocation(latitude: 48.8584, longitude: 2.2945)

        let result = try #require(mapper.searchResult(from: makeResult(title: "Eiffel Tower", location: location)))

        #expect(result.hasLocation)
    }

    @Test
    func fallsBackToTheTitleWhenDisplayFieldsAreMissing() throws {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])

        let result = try #require(mapper.searchResult(from: makeResult(title: "Cat")))

        #expect(result.title == "Cat")
        #expect(result.titleHTML == "Cat")
    }

    @Test
    func keepsTheCanonicalTitleApartFromTheDisplayTitle() throws {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])

        let result = try #require(mapper.searchResult(from: makeResult(title: "IPhone", displayTitle: "iPhone")))

        #expect(result.pageTitle == "IPhone")
        #expect(result.title == "iPhone")
        #expect(result.articleURL == englishSiteURL.wmf_URL(withTitle: "IPhone"))
    }

    @Test
    func dropsResultsWithoutATitle() {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])

        #expect(mapper.searchResult(from: makeResult(title: nil)) == nil)
    }

    @Test
    func resultsOutsideTheMainNamespaceAreNotSavable() throws {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])

        let result = try #require(mapper.searchResult(from: makeResult(title: "Talk:Cat", displayTitle: "Talk:Cat")))

        #expect(!result.isSavable)
        #expect(!result.isArticle)
    }

    @Test
    func descriptionCapitalizesTheFirstLetter() {
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [])

        #expect(mapper.description(for: makeResult(title: "Cat", wikidataDescription: "small domesticated mammal")) == "Small domesticated mammal")
    }

    @Test
    func descriptionCombinesTheRedirectAndTheWikidataDescription() {
        let mapping = MWKSearchRedirectMapping(fromTitle: "Felis", toTitle: "Cat")
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [mapping])

        let description = mapper.description(for: makeResult(title: "Cat", displayTitle: "Cat", wikidataDescription: "small domesticated mammal"))

        #expect(description == "Redirected from: Felis\nSmall domesticated mammal")
    }

    @Test
    func descriptionKeepsOnlyTheRedirectWhenThereIsNoWikidataDescription() {
        let mapping = MWKSearchRedirectMapping(fromTitle: "Felis", toTitle: "Cat")
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [mapping])

        #expect(mapper.description(for: makeResult(title: "Cat", displayTitle: "Cat")) == "Redirected from: Felis")
    }

    @Test
    func descriptionIsNilWithoutRedirectOrWikidataDescription() {
        let mapping = MWKSearchRedirectMapping(fromTitle: "Felis", toTitle: "Cat")
        let mapper = SearchResultsMapper(siteURL: englishSiteURL, redirectMappings: [mapping])

        #expect(mapper.description(for: makeResult(title: "Dog", displayTitle: "Dog")) == nil)
    }

    @Test
    func projectCarriesTheLanguageAndVariant() {
        var siteURL = URL(string: "https://zh.wikipedia.org")!
        siteURL.wmf_languageVariantCode = "zh-hans"
        let mapper = SearchResultsMapper(siteURL: siteURL, redirectMappings: [])

        #expect(mapper.project == .wikipedia(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-hans")))
    }

    private func makeResult(title: String?, displayTitle: String? = nil, displayTitleHTML: String? = nil, wikidataDescription: String? = nil, thumbnailURL: URL? = nil, location: CLLocation? = nil) -> MWKSearchResult {
        MWKSearchResult(articleID: 1, revID: 1, title: title, displayTitle: displayTitle, displayTitleHTML: displayTitleHTML, wikidataDescription: wikidataDescription, extract: nil, thumbnailURL: thumbnailURL, index: nil, titleNamespace: nil, location: location)
    }
}
