import Foundation


extension NSManagedObjectContext {
    public func clearReadHistory() throws {
        let request = WMFArticle.readHistoryFetchRequest
        request.fetchLimit = 500
        request.propertiesToFetch = []
        var articles = try fetch(request)
        while articles.count > 0 {
            try autoreleasepool { () in
                for article in articles {
                    article.removeFromReadHistoryWithoutSaving()
                }
                try save()
                reset()
            }
            articles = try fetch(request)
        }
    }
    
    @objc public var mostRecentlyReadArticle: WMFArticle? {
        let request = WMFArticle.readHistoryFetchRequest
        request.fetchLimit = 1
        return try? fetch(request).first
    }
}


extension WMFArticle {
    static var readHistoryFetchRequest: NSFetchRequest<WMFArticle> {
        let request = self.fetchRequest()
        request.predicate = NSPredicate(format: "viewedDate != NULL")
        request.sortDescriptors = [NSSortDescriptor(key: "viewedDate", ascending: false)]
        return request
    }
    
    public func addToReadHistory() throws {
        viewedDate = Date()
        updateViewedDateWithoutTime()
        try managedObjectContext?.save()
    }
    
    fileprivate func removeFromReadHistoryWithoutSaving() {
        viewedDate = nil
        wasSignificantlyViewed = false
        updateViewedDateWithoutTime()
    }
    
    public func removeFromReadHistory() throws {
        removeFromReadHistoryWithoutSaving()
        try managedObjectContext?.save()
    }
}
