import WMFData

extension MWKSavedPageList: SavedArticleSlideDataDelegate {
    public func getSavedArticleSlideData(from startDate: Date, to endDate: Date) async -> SavedArticleSlideData {
        await MainActor.run {
            let savedArticleCount = savedArticleCount(for: startDate, end: endDate)
            let articles = randomSavedArticles(from: startDate, to: endDate, count: SavedArticleSlideData.maximumArticleCount)
            let slideData = SavedArticleSlideData(savedArticlesCount: savedArticleCount, articleTitles: articles.map(\.title), articles: articles)
            return slideData
        }
    }

    /// Up to `count` articles saved in the window, picked at random, with a title to show.
    @MainActor
    private func randomSavedArticles(from startDate: Date, to endDate: Date, count: Int) -> [SavedArticleSlideData.Article] {
        guard let viewContext = dataStore?.viewContext else {
            return []
        }
        let request = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "savedDate >= %@ AND savedDate <= %@ AND displayTitle != nil", startDate as NSDate, endDate as NSDate)
        let savedArticles: [WMFArticle]
        do {
            savedArticles = try viewContext.fetch(request)
        } catch {
            return []
        }

        return savedArticles.shuffled().prefix(count).compactMap { article in
            guard let title = article.displayTitle, !title.isEmpty else {
                return nil
            }
            let url = article.url
            let project = url.flatMap { url -> WMFProject? in
                guard let languageCode = url.wmf_languageCode else {
                    return nil
                }
                return WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: article.variant))
            }
            let description = article.capitalizedWikidataDescription
            return SavedArticleSlideData.Article(
                title: title,
                pageTitle: url?.wmf_title,
                articleDescription: (description?.isEmpty ?? true) ? nil : description,
                projectID: project?.id
            )
        }
    }
}
