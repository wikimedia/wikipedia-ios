import CocoaLumberjackSwift

extension WMFArticle {
    
    @objc public func update(withRelatedPage page: RelatedPage) {
        if let thumbnail = page.thumbnail, let url = thumbnail.source {
            thumbnailURLString = url
            thumbnailURL = URL(string: url)
        }

        displayTitleHTML = page.title
        pageID = NSNumber(value: page.pageId)
        lastModifiedDate = DateFormatter.wmf_iso8601()?.date(from: page.touched)
        snippet = page.articleDescription
        wikidataDescription = page.articleDescription
    }
}

extension NSManagedObjectContext {
    @objc public func wmf_createOrUpdateArticleSummmaries(withRelatedPages relatedPages: [WMFInMemoryURLKey: RelatedPage]) throws -> [WMFInMemoryURLKey: WMFArticle] {
        guard !relatedPages.isEmpty else {
            return [:]
        }

        var keys: [WMFInMemoryURLKey] = []
        var reverseRedirectedKeys: [WMFInMemoryURLKey: WMFInMemoryURLKey] = [:]

        keys.reserveCapacity(relatedPages.count)

        for (key, page) in relatedPages {
            guard
                let pageKey = page.key,
                key != pageKey
            else {
                keys.append(key)
                continue
            }
            reverseRedirectedKeys[pageKey] = key
            keys.append(pageKey)
            do {
                let articlesWithKey = try fetchArticles(with: key.url)
                let articlesWithSummaryKey = try fetchArticles(with: pageKey.url)
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
                canonicalArticle.key = pageKey.databaseKey
                canonicalArticle.variant = pageKey.languageVariantCode
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
            guard let result = relatedPages[requestedKey] else {
                articles[requestedKey] = articleToUpdate
                continue
            }
            articleToUpdate.update(withRelatedPage: result)
            articles[requestedKey] = articleToUpdate
            keysToCreate.remove(articleKey)
        }

        for key in keysToCreate {
            let requestedKey = reverseRedirectedKeys[key] ?? key
            guard let result = relatedPages[requestedKey],
                  let article = self.createArticle(with: key.url) else {
                    continue
            }
            article.update(withRelatedPage: result)
            articles[requestedKey] = article
        }
        try self.save()
        return articles
    }
}
