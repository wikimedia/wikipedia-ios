extension WMFArticle {
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
        displayTitleHTMLString = summary.displayTitle
        snippet = summary.extract?.wmf_summaryFromText()
    
        if let summaryCoordinate = summary.coordinates {
            coordinate = CLLocationCoordinate2D(latitude: summaryCoordinate.lat, longitude: summaryCoordinate.lon)
        } else {
            coordinate = nil
        }
    }
}

public typealias ArticleSummariesByKey = [String: [String : Any]]

extension Dictionary where Key == String, Value == Any {
    var articleSummaryURL: URL? {
        guard
            let contentURLs = self["content_urls"] as? [String: Any],
            let desktopURLs = contentURLs["desktop"] as? [String: Any],
            let pageURLString = desktopURLs["page"] as? String
            else {
                return nil
        }
        return URL(string: pageURLString)
    }
}

extension Array where Element == [String: Any] {
    var articleSummariesByKey: ArticleSummariesByKey {
        let keysAndSummaries = compactMap { (summary) -> (String, [String: Any])? in
            guard
                let articleSummaryURL = summary.articleSummaryURL,
                let key = articleSummaryURL.wmf_articleDatabaseKey
                else {
                    return nil
            }
            return (key, summary)
        }
        return Dictionary(uniqueKeysWithValues: keysAndSummaries)
    }
}

extension NSManagedObjectContext {
    
    @objc public func wmf_createOrUpdateArticleSummmaries(withSummaryResponses summaryResponses: [String: ArticleSummary]) throws -> [WMFArticle] {
        let keys = summaryResponses.keys
        guard !keys.isEmpty else {
            return []
        }
        var keysToCreate = Set(keys)
        let articlesToUpdateFetchRequest = WMFArticle.fetchRequest()
        articlesToUpdateFetchRequest.predicate = NSPredicate(format: "key IN %@", Array(keys))
        var articles = try self.fetch(articlesToUpdateFetchRequest)
        for articleToUpdate in articles {
            guard let key = articleToUpdate.key,
                let result = summaryResponses[key] else {
                    continue
            }
            articleToUpdate.update(withSummary: result)
            keysToCreate.remove(key)
        }
        for key in keysToCreate {
            guard let result = summaryResponses[key],
                let article = self.createArticle(withKey: key) else {
                    continue
            }
            article.update(withSummary: result)
            articles.append(article)
        }
        try self.save()
        return articles
    }

    
    
}
