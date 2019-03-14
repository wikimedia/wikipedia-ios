extension WMFArticle {
    @objc public func update(withSummary summary: [String: Any]) {
        if let originalImage = summary["originalimage"] as? [String: Any],
            let source = originalImage["source"] as? String,
            let width = originalImage["width"] as? Int,
            let height = originalImage["height"] as? Int{
            self.imageURLString = source
            self.imageWidth = NSNumber(value: width)
            self.imageHeight = NSNumber(value: height)
        }
        
        if let description = summary["description"] as? String {
            self.wikidataDescription = description
        }
        
        if let displaytitle = summary["displaytitle"] as? String {
            self.displayTitleHTML = displaytitle
        }
        
        if let extract = summary["extract"] as? String {
            self.snippet = extract.wmf_summaryFromText()
        }
        
        if let coordinate = summary["coordinates"] as? [String: Any] ?? (summary["coordinates"] as? [[String: Any]])?.first,
            let lat = coordinate["lat"] as? Double,
            let lon = coordinate["lon"] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

public typealias ArticleSummariesByKey = [String: [String: Any]]

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
    
    @objc public func wmf_createOrUpdateArticleSummmaries(withSummaryResponses summaryResponses: ArticleSummariesByKey) throws -> [WMFArticle] {
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

    public func wmf_updateOrCreateArticleSummariesForArticles(withURLs articleURLs: [URL], completion: @escaping ([WMFArticle]) -> Void) {
        Session.shared.fetchArticleSummaryResponsesForArticles(withURLs: articleURLs) { (summaryResponses) in
            self.perform {
                do {
                    let articles = try self.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                    completion(articles)
                } catch let error {
                    DDLogError("Error fetching saved articles: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }
    
}
