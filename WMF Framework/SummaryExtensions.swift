extension WMFArticle {
    func merge(_ article: WMFArticle) {
        // merge important keys not set by the summary
        let keysToMerge = ["isExcludedFromFeed", "readingLists", "savedDate", "viewedDate", "viewedDateWithoutTime", "viewedFragment", "viewedScrollPosition", "wasSignificantlyViewed", "previewReadingLists", "placesSortOrder", "pageViews"]
        for key in keysToMerge {
            guard let value = article.primitiveValue(forKey: key) else {
                continue
            }
            if let setValue = value as? NSSet, setValue.count == 0 {
                continue
            }
            setPrimitiveValue(value, forKey: key)
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
        keys.reserveCapacity(summaryResponses.count)
        for (key, summary) in summaryResponses {
            guard
                let summaryKey = summary.key,
                key != summaryKey // find the mismatched keys
            else {
                keys.append(key)
                continue
            }
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
            guard let key = articleToUpdate.key,
                let result = summaryResponses[key] else {
                    continue
            }
            articleToUpdate.update(withSummary: result)
            articles[key] = articleToUpdate
            keysToCreate.remove(key)
        }
        for key in keysToCreate {
            guard let result = summaryResponses[key],
                let article = self.createArticle(withKey: key) else {
                    continue
            }
            article.update(withSummary: result)
            articles[key] = article
        }
        try self.save()
        return articles
    }
}
