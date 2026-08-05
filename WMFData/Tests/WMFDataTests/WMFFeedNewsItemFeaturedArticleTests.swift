import Testing
@testable import WMFData

@Suite
struct WMFFeedNewsItemFeaturedArticleTests {

    private func makeArticle(title: String, hasThumbnail: Bool) -> WMFFeedArticle {
        WMFFeedArticle(
            type: nil,
            title: title,
            displayTitle: title,
            normalizedTitle: title,
            namespace: nil,
            wikibaseItem: nil,
            titles: nil,
            pageid: nil,
            thumbnail: hasThumbnail ? WMFFeedImageSource(source: "https://example.org/\(title).jpg", width: 100, height: 100) : nil,
            originalImage: nil,
            lang: nil,
            dir: nil,
            revision: nil,
            tid: nil,
            timestamp: nil,
            description: nil,
            descriptionSource: nil,
            contentURLs: nil,
            extract: nil,
            extractHTML: nil
        )
    }

    @Test
    func picksTheArticleMarkedAsPictured() {
        let story = "Storm <a href=\"./Alice\">Alice</a> hits <a href=\"./Bruges\">Bruges</a> (pictured)."
        let item = WMFFeedNewsItem(story: story, links: [
            makeArticle(title: "Alice", hasThumbnail: true),
            makeArticle(title: "Bruges", hasThumbnail: true)
        ])

        // Not the first link — the one the story says is pictured
        #expect(item.featuredArticle(picturedText: "pictured")?.title == "Bruges")
    }

    @Test
    func skipsLinksWithoutThumbnails() {
        let story = "<a href=\"./Alice\">Alice</a> and <a href=\"./Bruges\">Bruges</a>."
        let item = WMFFeedNewsItem(story: story, links: [
            makeArticle(title: "Alice", hasThumbnail: false),
            makeArticle(title: "Bruges", hasThumbnail: true)
        ])

        // The old bug: taking links.first yields no image at all here
        #expect(item.featuredArticle(picturedText: "pictured")?.title == "Bruges")
    }

    @Test
    func fallsBackToFirstLinkWhenNoneHaveThumbnails() {
        let item = WMFFeedNewsItem(story: "No images here", links: [
            makeArticle(title: "Alice", hasThumbnail: false),
            makeArticle(title: "Bruges", hasThumbnail: false)
        ])
        #expect(item.featuredArticle(picturedText: "pictured")?.title == "Alice")
    }

    @Test
    func picturedArticleWithoutThumbnailDoesNotWin() {
        let story = "<a href=\"./Alice\">Alice</a> in <a href=\"./Bruges\">Bruges</a> (pictured)."
        let item = WMFFeedNewsItem(story: story, links: [
            makeArticle(title: "Alice", hasThumbnail: true),
            makeArticle(title: "Bruges", hasThumbnail: false)
        ])

        // Bruges is pictured but has no image, so the story still needs one that does
        #expect(item.featuredArticle(picturedText: "pictured")?.title == "Alice")
    }

    @Test
    func matchesLocalizedPicturedText() {
        let story = "Sturm <a href=\"./Alice\">Alice</a> trifft <a href=\"./Brügge\">Brügge</a> (Bild)."
        let item = WMFFeedNewsItem(story: story, links: [
            makeArticle(title: "Alice", hasThumbnail: true),
            makeArticle(title: "Brügge", hasThumbnail: true)
        ])
        #expect(item.featuredArticle(picturedText: "Bild")?.title == "Brügge")
    }

    @Test
    func underscoresInHrefBecomeSpaces() {
        let story = "<a href=\"./New_York_City\">New York City</a> (pictured)"
        #expect(WMFFeedNewsItem.picturedArticleTitle(fromStoryHTML: story, picturedText: "pictured") == "New York City")
    }

    @Test
    func noPicturedTextYieldsNoSemanticTitle() {
        let story = "<a href=\"./Alice\">Alice</a> did something."
        #expect(WMFFeedNewsItem.picturedArticleTitle(fromStoryHTML: story, picturedText: "pictured") == nil)
    }

    @Test
    func emptyLinksYieldNoFeaturedArticle() {
        let item = WMFFeedNewsItem(story: "Story", links: [])
        #expect(item.featuredArticle(picturedText: "pictured") == nil)
    }
}
