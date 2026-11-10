import CocoaLumberjackSwift
import WMFData

extension MWKSavedPageList: SavedArticleSlideDataDelegate {
    /// `nil` if the saved articles cannot be read, so the report does not freeze an empty slide.
    public func getSavedArticleSlideData(from startDate: Date, to endDate: Date) async -> SavedArticleSlideData? {
        await MainActor.run {
            savedArticleSlideData(from: startDate, to: endDate, count: SavedArticleSlideData.maximumArticleCount)
        }
    }

    /// Counts the articles saved in the window, and picks up to `count` of them at random. The count and
    /// the list come from one fetch with one filter, so a list is never empty while the count is not zero.
    /// The fetch loads only object IDs, so only the picked articles are loaded into the view context.
    @MainActor
    func savedArticleSlideData(from startDate: Date, to endDate: Date, count: Int) -> SavedArticleSlideData? {
        guard let viewContext = dataStore?.viewContext else {
            return nil
        }
        let request = NSFetchRequest<NSManagedObjectID>(entityName: "WMFArticle")
        request.predicate = NSPredicate(format: "savedDate >= %@ AND savedDate <= %@", startDate as NSDate, endDate as NSDate)
        request.resultType = .managedObjectIDResultType
        let savedArticleIDs: [NSManagedObjectID]
        do {
            savedArticleIDs = try viewContext.fetch(request)
        } catch {
            DDLogError("Year in Review: could not fetch saved articles: \(error)")
            return nil
        }

        let articles = savedArticleIDs.shuffled().prefix(count).compactMap { objectID -> SavedArticleSlideData.Article? in
            guard let article = try? viewContext.existingObject(with: objectID) as? WMFArticle else {
                return nil
            }
            return Self.slideArticle(from: article)
        }
        return SavedArticleSlideData(savedArticlesCount: savedArticleIDs.count, articles: articles)
    }

    /// An article synced from a reading list has no display title until its summary downloads, so the
    /// title falls back to the title in its URL.
    @MainActor
    static func slideArticle(from article: WMFArticle) -> SavedArticleSlideData.Article? {
        let url = article.url
        let pageTitle = url?.wmf_title
        let displayTitle = article.displayTitle.flatMap { $0.isEmpty ? nil : $0 }
        guard let title = displayTitle ?? pageTitle.flatMap({ $0.isEmpty ? nil : $0 }) else {
            return nil
        }
        let project = url.flatMap { url -> WMFProject? in
            guard let languageCode = url.wmf_languageCode else {
                return nil
            }
            return WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: article.variant))
        }
        let description = article.capitalizedWikidataDescription
        return SavedArticleSlideData.Article(
            title: title,
            pageTitle: pageTitle,
            articleDescription: (description?.isEmpty ?? true) ? nil : description,
            projectID: project?.id
        )
    }
}
