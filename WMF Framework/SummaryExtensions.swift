extension WMFArticle {
    @objc public func update(withSummary summary: ArticleSummary) {
        if let summaryKey = summary.articleURL?.wmf_articleDatabaseKey, summaryKey != key {
            key = summaryKey
        }
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
        let keys = summaryResponses.keys
        guard !keys.isEmpty else {
            return [:]
        }
        var keysToCreate = Set(keys)
        let articlesToUpdateFetchRequest = WMFArticle.fetchRequest()
        articlesToUpdateFetchRequest.predicate = NSPredicate(format: "key IN %@", Array(keys))
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
