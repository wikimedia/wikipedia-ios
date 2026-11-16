import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

/// Core Data declares `WMFContentGroup.contentPreview` as a copy property. Thus the setter calls
/// `copyWithZone:` on the value. The Mantle models conformed to NSCopying. The Swift replacements
/// must do the same, or the app stops with an unrecognized selector.
struct FeedBridgeModelCopyTests {

    private let articleURL = URL(string: "https://en.wikipedia.org/wiki/Cat")!
    private let thumbnailURL = URL(string: "https://upload.wikimedia.org/thumb.jpg")!
    private let imageURL = URL(string: "https://upload.wikimedia.org/image.jpg")!

    private func makePreview() -> WMFFeedArticlePreview {
        WMFFeedArticlePreview(
            articleURL: articleURL,
            displayTitle: "Cat",
            displayTitleHTML: "<i>Cat</i>",
            wikidataDescription: "A small mammal",
            snippet: "The cat is a small mammal.",
            thumbnailURL: thumbnailURL,
            imageURLString: imageURL.absoluteString,
            imageWidth: 100,
            imageHeight: 200
        )
    }

    private func makeImage() -> WMFFeedImage {
        WMFFeedImage(
            canonicalPageTitle: "File:Cat.jpg",
            imageDescription: "A cat",
            imageDescriptionIsRTL: false,
            imageThumbURL: thumbnailURL,
            imageURL: imageURL,
            imageWidth: 100,
            imageHeight: 200
        )
    }

    // MARK: - Every archived class answers copy

    @Test
    func articlePreviewCopyKeepsTheValues() throws {
        let original = makePreview()
        let copy = try #require(original.copy() as? WMFFeedArticlePreview)

        #expect(copy !== original)
        #expect(copy == original)
        #expect(copy.articleURL == articleURL)
        #expect(copy.displayTitleHTML == "<i>Cat</i>")
        #expect(copy.snippet == "The cat is a small mammal.")
        #expect(copy.imageWidth == 100)
    }

    @Test
    func topReadPreviewCopyKeepsItsClassAndCounts() throws {
        let original = WMFFeedTopReadArticlePreview(
            articleURL: articleURL,
            displayTitle: "Cat",
            displayTitleHTML: "<i>Cat</i>",
            wikidataDescription: "A small mammal",
            snippet: "The cat is a small mammal.",
            thumbnailURL: thumbnailURL,
            imageURLString: imageURL.absoluteString,
            imageWidth: 100,
            imageHeight: 200,
            numberOfViews: 42,
            rank: 7
        )

        let copy = try #require(original.copy() as? WMFFeedTopReadArticlePreview)

        #expect(copy !== original)
        #expect(copy.numberOfViews == 42)
        #expect(copy.rank == 7)
        #expect(copy.displayTitle == "Cat")
    }

    @Test
    func newsStoryCopyKeepsTheFeaturedPreview() throws {
        let preview = makePreview()
        let original = WMFFeedNewsStory(
            storyHTML: "<!--Aug 12--><b>Something</b> happened.",
            articlePreviews: [preview],
            featuredArticlePreview: preview,
            midnightUTCMonthAndDay: Date(timeIntervalSince1970: 0)
        )

        let copy = try #require(original.copy() as? WMFFeedNewsStory)

        #expect(copy !== original)
        #expect(copy.storyHTML == original.storyHTML)
        #expect(copy.articlePreviews?.count == 1)
        #expect(copy.featuredArticlePreview === preview, "The copy is shallow, as the Mantle copy was.")
    }

    @Test
    func onThisDayEventCopyKeepsTheScoreAndIndex() throws {
        let original = WMFFeedOnThisDayEvent(text: "A thing happened.", year: 1969, articlePreviews: [makePreview()])
        original.score = 2.5
        original.index = 3

        let copy = try #require(original.copy() as? WMFFeedOnThisDayEvent)

        #expect(copy !== original)
        #expect(copy.text == "A thing happened.")
        #expect(copy.year == 1969)
        #expect(copy.score == 2.5)
        #expect(copy.index == 3)
    }

    @Test
    func imageCopyKeepsTheURLs() throws {
        let original = makeImage()
        let copy = try #require(original.copy() as? WMFFeedImage)

        #expect(copy !== original)
        #expect(copy.imageURL == imageURL)
        #expect(copy.imageThumbURL == thumbnailURL)
        #expect(copy.canonicalPageTitle == "File:Cat.jpg")
    }

    @Test
    func searchResultCopyKeepsItsClassAndGeoValues() throws {
        let original = MWKSearchResult(articleID: 1, revID: 2, title: "Cat", displayTitle: "Cat", displayTitleHTML: "<i>Cat</i>", wikidataDescription: "A small mammal", extract: "A cat.", thumbnailURL: thumbnailURL, index: 1, titleNamespace: 0, location: nil)
        original.geoDimension = 1000
        original.geoType = 5
        original.viewCounts = [1, 2, 3]

        let copy = try #require(original.copy() as? MWKSearchResult)

        #expect(copy !== original)
        #expect(copy.articleID == 1)
        #expect(copy.displayTitleHTML == "<i>Cat</i>")
        #expect(copy.geoDimension == 1000)
        #expect(copy.geoType == 5)
        #expect(copy.viewCounts == [1, 2, 3])
    }

    // MARK: - The content group setter

    /// The setter of a copy property is the path that stopped the app. This test drives the
    /// selector the same way, without Core Data.
    @Test
    func everyArchivedClassRespondsToCopyWithZone() {
        let objects: [NSObject] = [makePreview(), makeImage()]
        for object in objects {
            #expect(object.responds(to: NSSelectorFromString("copyWithZone:")), "\(type(of: object)) must answer copyWithZone:")
        }
    }
}
