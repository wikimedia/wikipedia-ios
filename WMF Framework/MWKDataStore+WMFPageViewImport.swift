import WMFData
import CocoaLumberjackSwift

extension MWKDataStore {
    @objc func importViewedArticlesIntoWMFData(dataStoreMOC: NSManagedObjectContext) {
        guard let dataController = try? WMFPageViewsDataController() else {
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        var dateComponents = DateComponents()
        dateComponents.year = currentYear
        dateComponents.day = 1
        dateComponents.month = 1
        
        guard let oneYearAgoDate = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate >= %@", oneYearAgoDate as CVarArg)
        do {
            let articles = try dataStoreMOC.fetch(articleRequest)
            
            let importRequests: [WMFPageViewImportRequest] = articles.compactMap { article in
                guard let key = article.key,
                      let viewedDate = article.viewedDate else {
                    return nil
                }
                
                let url = URL(string: key)
                guard let languageCode = url?.wmf_languageCode,
                let title = url?.wmf_title else {
                    return nil
                }
                
                let language = WMFLanguage(languageCode: languageCode, languageVariantCode: article.variant)
                let project = WMFProject.wikipedia(language)
                
                return WMFPageViewImportRequest(title: title, project: project, viewedDate: viewedDate)
            }
            
            Task {
                do {
                    try await dataController.importPageViews(requests: importRequests)
                } catch {
                    DDLogError("Error importing WMFPageViewImportRequests: \(error)")
                }
            }
            
            
        } catch {
            DDLogError("Error fetching viewed WMFArticles: \(error)")
        }
        
    }
    
}
