import CocoaLumberjackSwift

extension WMFArticle {
    func merge(_ article: WMFArticle) {
        guard article.objectID != objectID else {
            return
        }
        // merge important keys not set by the summary
        let keysToMerge = [#keyPath(WMFArticle.savedDate), #keyPath(WMFArticle.placesSortOrder), #keyPath(WMFArticle.pageViews)]
        for key in keysToMerge {
            guard let valueToMerge = article.value(forKey: key) else {
                continue
            }
            // keep the later date when both have date values
            if let dateValueToMerge = valueToMerge as? Date, let dateValue = value(forKey: key) as? Date, dateValue > dateValueToMerge {
                continue
            }
            // prefer existing values
            if value(forKey: key) != nil {
               continue
            }
            setValue(valueToMerge, forKey: key)
        }
        
        if let articleReadingLists = article.readingLists {
            addReadingLists(articleReadingLists)
        }
        
        if let articlePreviewReadingLists = article.previewReadingLists {
            addPreviewReadingLists(articlePreviewReadingLists)
        }
        
        if article.isExcludedFromFeed {
            isExcludedFromFeed = true
        }
        
        let mergeViewedProperties: Bool
        if let viewedDateToMerge = article.viewedDate {
            if let existingViewedDate = viewedDate, existingViewedDate > viewedDateToMerge {
                mergeViewedProperties = false
            } else {
                mergeViewedProperties = true
            }
        } else {
            mergeViewedProperties = false
        }
        
        if mergeViewedProperties {
            viewedDate = article.viewedDate
            viewedFragment = article.viewedFragment
            viewedScrollPosition = article.viewedScrollPosition
            wasSignificantlyViewed = article.wasSignificantlyViewed
        }
    }
    
    @objc public func update(withSummary summary: ArticleSummary) {
        if let original = summary.original {
            imageURLString = original.source
            imageWidth = NSNumber(value: original.width)
            imageHeight = NSNumber(value: original.height)
        } else {
            imageURLString = nil
            imageWidth = NSNumber(value: 0)
            imageHeight = NSNumber(value: 0)
        }
        
        if let thumbnail = summary.thumbnail {
            thumbnailURLString = thumbnail.source
            thumbnailURL = thumbnail.url
        }
       
        wikidataDescription = summary.articleDescription
        wikidataID = summary.wikidataID
        displayTitleHTML = summary.displayTitle ?? summary.title ?? ""
        snippet = summary.extract?.wmf_summaryFromText()
        
        if let summaryCoordinate = summary.coordinates {
            coordinate = CLLocationCoordinate2D(latitude: summaryCoordinate.lat, longitude: summaryCoordinate.lon)
        } else {
            coordinate = nil
        }
        if let id = summary.id {
            pageID = NSNumber(value: id)
        } else {
            pageID = nil
        }
        if let timestamp = summary.timestamp {
            lastModifiedDate = DateFormatter.wmf_iso8601()?.date(from: timestamp)
        } else {
            lastModifiedDate = nil
        }
    }
}

extension NSManagedObjectContext {
    @objc public func wmf_createOrUpdateArticleSummmaries(withSummaryResponses summaryResponses: [WMFInMemoryURLKey: ArticleSummary]) throws -> [WMFInMemoryURLKey: WMFArticle] {
        guard !summaryResponses.isEmpty else {
            return [:]
        }
        var keys: [WMFInMemoryURLKey] = []
        var reverseRedirectedKeys: [WMFInMemoryURLKey: WMFInMemoryURLKey] = [:]
        keys.reserveCapacity(summaryResponses.count)
        for (key, summary) in summaryResponses {
            guard
                let summaryKey = summary.key,
                key != summaryKey // find the mismatched keys
            else {
                keys.append(key)
                continue
            }
            reverseRedirectedKeys[summaryKey] = key
            keys.append(summaryKey)
            do {
                let articlesWithKey = try fetchArticles(with: key.url)
                let articlesWithSummaryKey = try fetchArticles(with: summaryKey.url)
                guard let canonicalArticle = articlesWithSummaryKey.first ?? articlesWithKey.first else {
                    continue
                }
                for article in articlesWithKey {
                    canonicalArticle.merge(article)
                    delete(article)
                }
                for article in articlesWithSummaryKey {
                    canonicalArticle.merge(article)
                    delete(article)
                }
                canonicalArticle.key = summaryKey.databaseKey
                canonicalArticle.variant = summaryKey.languageVariantCode
            } catch let error {
                DDLogError("Error fetching articles for merge: \(error)")
            }
        }
        var keysToCreate = Set(keys)
        var articles: [WMFInMemoryURLKey: WMFArticle] = [:]
        articles.reserveCapacity(keys.count)
        let fetchedArticles = try self.fetchArticlesWithInMemoryURLKeys(keys)
        for articleToUpdate in fetchedArticles {
            guard let articleKey = articleToUpdate.inMemoryKey else {
                    continue
            }
            let requestedKey = reverseRedirectedKeys[articleKey] ?? articleKey
            guard let result = summaryResponses[requestedKey] else {
                articles[requestedKey] = articleToUpdate
                continue
            }
            articleToUpdate.update(withSummary: result)
            articles[requestedKey] = articleToUpdate
            keysToCreate.remove(articleKey)
        }
        for key in keysToCreate {
            let requestedKey = reverseRedirectedKeys[key] ?? key
            guard let result = summaryResponses[requestedKey], // responses are by requested key
                  let article = self.createArticle(with: key.url) else { // article should have redirected key
                    continue
            }
            article.update(withSummary: result)
            articles[requestedKey] = article
        }
        try self.save()
        return articles
    }
}
