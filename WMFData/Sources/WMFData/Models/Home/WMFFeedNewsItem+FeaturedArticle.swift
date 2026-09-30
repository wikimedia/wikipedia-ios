import Foundation

public extension WMFFeedNewsItem {

    /// The article that best represents a news story visually — used to pick the story's image.
    ///
    /// Ports the legacy explore feed's rule (`WMFFeedContentSource` + `WMFFeedNewsStory`):
    /// stories often mark one linked article as "pictured", and that article's thumbnail is the
    /// one the story is illustrated with. Falling back to the first link is wrong when that link
    /// has no thumbnail, which is why the legacy feed skips thumbnail-less links.
    ///
    /// - Parameter picturedText: the localized word for "pictured" **in the wiki's language**
    ///   (the story HTML is in that language, not the app's UI language). Kept as a parameter so
    ///   WMFData stays free of localized strings.
    func featuredArticle(picturedText: String) -> WMFFeedArticle? {
        let links = links ?? []
        let semanticTitle = Self.picturedArticleTitle(fromStoryHTML: story, picturedText: picturedText)

        var firstWithThumbnail: WMFFeedArticle?
        for link in links where link.thumbnail?.source != nil {
            if let semanticTitle, link.matchesTitle(semanticTitle) {
                return link
            }
            if firstWithThumbnail == nil {
                firstWithThumbnail = link
            }
        }

        // No link has a thumbnail: fall back to the first so callers still get a title.
        return firstWithThumbnail ?? links.first
    }

    /// The title of the article the story marks as pictured, found by locating the localized
    /// "pictured" text and walking back to the anchor tag that precedes it.
    static func picturedArticleTitle(fromStoryHTML storyHTML: String?, picturedText: String) -> String? {
        guard let storyHTML, !picturedText.isEmpty,
              let picturedRange = storyHTML.range(of: picturedText, options: .caseInsensitive) else {
            return nil
        }

        let beforePictured = storyHTML[storyHTML.startIndex..<picturedRange.lowerBound]
        guard let anchorStart = beforePictured.range(of: "<a", options: .backwards) else {
            return nil
        }

        let fromAnchor = storyHTML[anchorStart.upperBound...]
        guard let anchorEnd = fromAnchor.range(of: ">") else {
            return nil
        }

        let anchorAttributes = String(fromAnchor[fromAnchor.startIndex..<anchorEnd.lowerBound])
        guard let href = Self.href(inAnchorAttributes: anchorAttributes) else {
            return nil
        }

        return Self.title(fromHref: href)
    }

    private static func href(inAnchorAttributes attributes: String) -> String? {
        // href="..." / href='...' / href=...
        let pattern = "href\\s*=\\s*[\"']?([^\"'\\s>]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: attributes, range: NSRange(attributes.startIndex..., in: attributes)),
              let range = Range(match.range(at: 1), in: attributes) else {
            return nil
        }
        return String(attributes[range])
    }

    private static func title(fromHref href: String) -> String? {
        // REST feed story links are relative ("./Article_title"); absolute URLs also appear.
        var titleComponent: String?
        if href.hasPrefix("./") {
            titleComponent = String(href.dropFirst(2))
        } else if let url = URL(string: href) {
            titleComponent = url.lastPathComponent
        }

        guard let titleComponent, !titleComponent.isEmpty else { return nil }
        let decoded = titleComponent.removingPercentEncoding ?? titleComponent
        return decoded.replacingOccurrences(of: "_", with: " ")
    }
}

private extension WMFFeedArticle {
    /// The story's link gives a page title; the article carries several title spellings, so
    /// compare against each rather than assuming which one the feed populated.
    func matchesTitle(_ candidate: String) -> Bool {
        let titles = [normalizedTitle, title, displayTitle].compactMap { $0 }
        return titles.contains { $0.compare(candidate, options: .caseInsensitive) == .orderedSame }
    }
}
