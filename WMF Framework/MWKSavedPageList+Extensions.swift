import WMFData

extension MWKSavedPageList: SavedArticleSlideDataDelegate {
    public func getSavedArticleSlideData(from startDate: Date, to endDate: Date) async -> SavedArticleSlideData {
        await MainActor.run {
            let savedArticleCount = savedArticleCount(for: startDate, end: endDate)
            let savedArticleTitles = randomSavedArticleTitles(for: startDate, end: endDate)
            let slideData = SavedArticleSlideData(savedArticlesCount: savedArticleCount, articleTitles: savedArticleTitles)
            return slideData
        }
    }
}
