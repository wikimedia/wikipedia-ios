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
        
        if let title = summary["title"] as? String {
            self.displayTitle = title
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

extension URLSession {
    public func wmf_jsonDictionaryTask(with request: URLRequest, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        return self.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            do {
                guard data.count > 0, let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(nil, response, nil)
                    return
                }
                completionHandler(responseObject, response, nil)
            } catch let error {
                DDLogError("Error parsing JSON: \(error)")
                completionHandler(nil, response, error)
            }
        })
    }
    
    
    public func wmf_summaryTask(with articleURL: URL, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let siteURL = articleURL.wmf_site, let title = articleURL.wmf_titleWithUnderscores else {
            return nil
        }
        
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.wmf_urlPathComponentAllowed) ?? title
        let percentEncodedPath = NSString.path(withComponents: ["/api", "rest_v1", "page", "summary", encodedTitle])
        
        guard var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.percentEncodedPath = percentEncodedPath
        guard let summaryURL = components.url else {
            return nil
        }

        var request = URLRequest(url: summaryURL)
        //The accept profile is case sensitive https://gerrit.wikimedia.org/r/#/c/356429/
        request.setValue("application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.1.2\"", forHTTPHeaderField: "Accept")
        return wmf_jsonDictionaryTask(with: request, completionHandler: completionHandler)
    }
    
    @objc(wmf_fetchSummaryWithArticleURL:completionHandler:)
    public func wmf_fetchSummary(with articleURL: URL, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) {
        guard let task = wmf_summaryTask(with: articleURL, completionHandler: completionHandler) else {
            completionHandler(nil, nil, NSError.wmf_error(with: .invalidRequestParameters))
            return
        }
        task.resume()
    }
}

extension NSManagedObjectContext {
    
    public func wmf_createOrUpdateArticleSummmaries(withSummaryResponses summaryResponses: [String: [String: Any]]) throws -> [WMFArticle] {
        let keys = summaryResponses.keys
        guard keys.count > 0 else {
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
        let session = URLSession.shared
        let queue = DispatchQueue(label: "ArticleSummaryFetch-" + UUID().uuidString)
        let taskGroup = WMFTaskGroup()
        var summaryResponses: [String: [String: Any]] = [:]
        for articleURL in articleURLs {
            guard let key = articleURL.wmf_articleDatabaseKey else {
                continue
            }
            taskGroup.enter()
            session.wmf_fetchSummary(with: articleURL, completionHandler: { (responseObject, response, error) in
                guard let responseObject = responseObject else {
                    taskGroup.leave()
                    return
                }
                queue.async {
                    summaryResponses[key] = responseObject
                    taskGroup.leave()
                }
            })
        }
        taskGroup.waitInBackgroundAndNotify(on: queue) {
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
