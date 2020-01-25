
enum MigrateMobileviewToMobileHTMLIfNecessaryError: Error {
    case noArticleURL
    case noArticleCacheController
    case noMobileHTML
}

@objc extension WMFArticle {
    
    // TODO: use this method's completion block when loading articles (in case a mobileview conversion hasn't happened yet for that article's saved data for any reason)
    func migrateMobileviewToMobileHTMLIfNecessary(dataStore: MWKDataStore, completionHandler: @escaping ((Error?) -> Void)) {
        guard self.isConversionFromMobileviewNeeded == true else {
            // If conversion was previously attempted don't try again.
            completionHandler(nil)
            return
        }
        guard let articleURL = self.url else {
            assertionFailure("Could not get article url")
            completionHandler(MigrateMobileviewToMobileHTMLIfNecessaryError.noArticleURL)
            return
        }

        guard let articleCacheController = dataStore.articleCacheControllerWrapper.cacheController as? ArticleCacheController else {
            completionHandler(MigrateMobileviewToMobileHTMLIfNecessaryError.noArticleCacheController)
            return
        }
        
        let mwkArticle = dataStore.article(with: articleURL)

        dataStore.mobileviewConverter.convertMobileviewSavedDataToMobileHTML(article: mwkArticle) { (result, error) in
            let blastMobileviewSavedDataFolder = {
                // Remove old mobileview saved data folder for this article
                do {
                    try FileManager.default.removeItem(atPath: dataStore.path(forArticleURL: articleURL))
                } catch {
                    DDLogError("Could not remove mobileview folder for articleURL: \(articleURL)")
                }
            }
            
            let handleConversionFailure = {
                // No need to keep mobileview section html if conversion failed, so ok to remove section data
                // because we're setting `isDownloaded` next so saved article fetching will re-download from
                // new mobilehtml endpoint.
                blastMobileviewSavedDataFolder()

                // If conversion failed above for any reason set "article.isDownloaded" to false so normal fetching logic picks it up
                do {
                    self.isDownloaded = false
                    try dataStore.save()
                } catch let error {
                    DDLogError("Error updating article: \(error)")
                }
            }
            
            guard error == nil, let result = result else {
                handleConversionFailure()
                completionHandler(error)
                assertionFailure("Conversion error or no result")
                return
            }
            guard let mobileHTML = result as? String else {
                handleConversionFailure()
                completionHandler(MigrateMobileviewToMobileHTMLIfNecessaryError.noMobileHTML)
                assertionFailure("mobileHTML not extracted")
                return
            }

            articleCacheController.cacheFromMigration(desktopArticleURL: articleURL, content: mobileHTML, mimeType: "text/html"){ error in
                // Conversion succeeded so can safely blast old mobileview folder.
                blastMobileviewSavedDataFolder()
                
                do {
                    self.isConversionFromMobileviewNeeded = false
                    try dataStore.save()
                } catch let error {
                    completionHandler(error)
                    DDLogError("Error updating article: \(error)")
                    return
                }
                
                completionHandler(nil)
            }
        }
    }
}
