extension WMFArticle {
    func merge(_ article: WMFArticle) {
        // merge important keys not set by the summary
        let keysToMerge = ["isExcludedFromFeed", "readingLists", "savedDate", "viewedDate", "viewedDateWithoutTime", "viewedFragment", "viewedScrollPosition", "wasSignificantlyViewed", "previewReadingLists", "placesSortOrder", "pageViews"]
        // ensure these values still exist with an assertion. is there a way to use these directly?
        assert([\WMFArticle.isExcludedFromFeed, \WMFArticle.readingLists, \WMFArticle.savedDate, \WMFArticle.viewedDate, \WMFArticle.viewedDateWithoutTime, \WMFArticle.viewedFragment, \WMFArticle.viewedScrollPosition, \WMFArticle.wasSignificantlyViewed, \WMFArticle.previewReadingLists, \WMFArticle.placesSortOrder, \WMFArticle.pageViews].count == keysToMerge.count)
        for key in keysToMerge {
            guard let value = article.value(forKey: key) else {
                continue
            }
            if let setValue = value as? NSSet, setValue.count == 0 {
                continue
            }
            setValue(value, forKey: key)
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
       
        wikidataDescription = summary.articleDescription
        displayTitleHTML = summary.displayTitle ?? summary.title ?? ""
        snippet = summary.extract?.wmf_summaryFromText()
        
        let namespace: Int = summary.namespace?.id ?? 0
        ns = NSNumber(value: namespace)
        isExcludedFromFeed = isExcludedFromFeed || namespace != 0

        if let summaryCoordinate = summary.coordinates {
            coordinate = CLLocationCoordinate2D(latitude: summaryCoordinate.lat, longitude: summaryCoordinate.lon)
        } else {
            coordinate = nil
        }
    }
}

extension NSManagedObjectContext {
    @objc public func wmf_createOrUpdateArticleSummmaries(withSummaryResponses summaryResponses: [String: ArticleSummary]) throws -> [String: WMFArticle] {
        guard !summaryResponses.isEmpty else {
            return [:]
        }
        var keys: [String] = []
        var redirectedKeys: [String: String] = [:]
        var reverseRedirectedKeys: [String: String] = [:]
        keys.reserveCapacity(summaryResponses.count)
        for (key, summary) in summaryResponses {
            guard
                let summaryKey = summary.key,
                key != summaryKey // find the mismatched keys
            else {
                keys.append(key)
                continue
            }
            redirectedKeys[key] = summaryKey
            reverseRedirectedKeys[summaryKey] = key
            keys.append(summaryKey)
            do {
                let articlesWithKey = try fetchArticles(withKey: key)
                let articlesWithSummaryKey = try fetchArticles(withKey: summaryKey)
                guard let canonicalArticle = articlesWithSummaryKey.first ?? articlesWithKey.first else {
                    continue
                }
                for article in articlesWithKey {
                    guard article.objectID != canonicalArticle.objectID else {
                        continue
                    }
                    canonicalArticle.merge(article)
                    delete(article)
                }
                for article in articlesWithSummaryKey {
                    guard article.objectID != canonicalArticle.objectID else {
                        continue
                    }
                    canonicalArticle.merge(article)
                    delete(article)
                }
                canonicalArticle.key = summaryKey
            } catch let error {
                DDLogError("Error fetching articles for merge: \(error)")
            }
        }
        var keysToCreate = Set(keys)
        let articlesToUpdateFetchRequest = WMFArticle.fetchRequest()
        articlesToUpdateFetchRequest.predicate = NSPredicate(format: "key IN %@", keys)
        var articles: [String: WMFArticle] = [:]
        articles.reserveCapacity(keys.count)
        let fetchedArticles = try self.fetch(articlesToUpdateFetchRequest)
        for articleToUpdate in fetchedArticles {
            guard let articleKey = articleToUpdate.key else {
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
        for requestedKey in keysToCreate {
            let key = redirectedKeys[requestedKey] ?? requestedKey
            guard let result = summaryResponses[requestedKey], // responses are by requested key
                let article = self.createArticle(withKey: key) else { // article should have redirected key
                    continue
            }
            article.update(withSummary: result)
            articles[requestedKey] = article
        }
        try self.save()
        return articles
    }
}
