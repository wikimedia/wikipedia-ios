extension WMFFeedDisplayType {
    public func imageWidthCompatibleWithTraitCollection(_ traitCollection: UITraitCollection) -> Int {
        switch self {
        case .pageWithPreview, .relatedPagesSourceArticle, .random, .continueReading:
            return traitCollection.wmf_leadImageWidth
        default:
            return traitCollection.wmf_nearbyThumbnailWidth
        }
    }
}

extension WMFContentGroup {
    public func imageURLsCompatibleWithTraitCollection(_ traitCollection: UITraitCollection, dataStore: MWKDataStore, viewSize: CGSize? = nil) -> Set<URL>? {
        switch contentGroupKind {
        case .pictureOfTheDay:
            guard let imageInfo = contentPreview as? WMFFeedImage else {
                return nil
            }
            
            let fallback: (WMFFeedImage, UITraitCollection) -> URL = { imageInfo, traitCollection in
                let imageURL = URL(string: WMFChangeImageSourceURLSizePrefix(imageInfo.imageThumbURL.absoluteString, traitCollection.wmf_leadImageWidth)) ?? imageInfo.imageThumbURL
                return imageURL
            }
            
            guard let viewSize = viewSize else {
                return [fallback(imageInfo, traitCollection)]
            }
            
            let scaledViewSize = CGSize(width: UIScreen.main.scale * viewSize.width, height: UIScreen.main.scale * viewSize.height)
            let imageURL = imageInfo.getImageURL(forWidth: Double(scaledViewSize.width), height: Double(scaledViewSize.height)) ??
                fallback(imageInfo, traitCollection)
            return [imageURL]

        case .announcement:
            guard let announcement = contentPreview as? WMFAnnouncement else {
                return nil
            }
            guard let imageURL = announcement.imageURL else {
                return nil
            }
            return [imageURL]
        default:
            let count = countOfPreviewItems
            guard count > 0 else {
                return nil
            }
            var imageURLs: Set<URL> = []
            imageURLs.reserveCapacity(count)
            for index in 0..<count {
                guard let articleURL = previewArticleURLForItemAtIndex(index) else {
                    continue
                }
                guard let article = dataStore.fetchArticle(with: articleURL) else {
                    continue
                }
                let displayType = displayTypeForItem(at: index)
                let imageWidthToRequest = displayType.imageWidthCompatibleWithTraitCollection(traitCollection)
                guard let imageURL = article.imageURL(forWidth: imageWidthToRequest) else {
                    continue
                }
                imageURLs.insert(imageURL)
            }
            return imageURLs
        }
    }
    
    public var contentURLs: [URL]? {
        switch contentType {
        case .topReadPreview:
            guard let previews = fullContent?.object as? [WMFFeedTopReadArticlePreview] else {
                return nil
            }
            return previews.compactMap { $0.articleURL }
        case .story:
            guard let stories = fullContent?.object as? [WMFFeedNewsStory] else {
                return nil
            }
            return stories.compactMap { $0.featuredArticlePreview?.articleURL ?? $0.articlePreviews?.first?.articleURL }
        case .URL:
            return fullContent?.object as? [URL]
        default:
            return nil
        }
    }
    
    public var countOfPreviewItems: Int {
        guard let preview = contentPreview as? [Any] else {
            return 1
        }
        let countOfFeedContent = preview.count
        switch contentGroupKind {
        case .news, .location:
            return 1
        case .onThisDay:
            return min(countOfFeedContent, 2)
        case .relatedPages:
            return min(countOfFeedContent, Int(maxNumberOfCells)) + 1
        default:
            return min(countOfFeedContent, Int(maxNumberOfCells))
        }
    }
    
    public func previewArticleURLForItemAtIndex(_ index: Int) -> URL? {
        let displayType = displayTypeForItem(at: index)
        var index = index
        switch displayType {
        case .relatedPagesSourceArticle:
            return articleURL
        case .relatedPages:
            index -= 1
        case .ranked:
            guard let content = contentPreview as? [WMFFeedTopReadArticlePreview], content.count > index else {
                return nil
            }
            return content[index].articleURL
        default:
            break
        }
        
        if let contentURL = contentPreview as? URL {
            return contentURL
        }
        
        guard let content = contentPreview as? [URL], content.count > index else {
            return nil
        }
        
        return content[index]
    }
    
    public var isSelectable: Bool {
        guard undoType == .none else {
            return false
        }
        switch contentGroupKind {
        case .announcement, .notification, .theme, .readingList:
            return false
        default:
            return true
        }
    }
    
    public var previewArticleKeys: Set<WMFInMemoryURLKey> {
        guard countOfPreviewItems > 0 else {
            return []
        }
        var articleKeys: Set<WMFInMemoryURLKey> = []
        articleKeys.reserveCapacity(countOfPreviewItems)
        for i in 0...countOfPreviewItems {
            guard let key = previewArticleURLForItemAtIndex(i)?.wmf_inMemoryKey else {
                continue
            }
            articleKeys.insert(key)
        }
        return articleKeys
    }
}
