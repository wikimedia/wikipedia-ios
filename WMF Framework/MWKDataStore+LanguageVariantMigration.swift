import Foundation
import CocoaLumberjackSwift

extension MWKDataStore {
    @objc(migrateToLanguageVariantsForLanguageCodes:inManagedObjectContext:)
    public func migrateToLanguageVariants(for languageCodes: [String], in moc: NSManagedObjectContext) {
        
        // Map all languages with variants being migrated to the user's preferred variant
        // Note that even if the user does not have any preferred languages that match,
        // the user could have chosen to read or save an article in any language.
        // The variant is therefore determined for all langauges being migrated.
        let migrationMapping = languageCodes.reduce(into: [String:String]()) { (result, languageCode) in
            guard let languageVariantCode = NSLocale.wmf_bestLanguageVariantCodeForLanguageCode(languageCode) else {
                assertionFailure("No variant found for language code \(languageCode). Every language migrating to use language variants should return a language variant code")
                return
            }
            result[languageCode] = languageVariantCode
        }
        
        languageLinkController.migratePreferredLanguages(toLanguageVariants: migrationMapping, in: moc)
        feedContentController.migrateExploreFeedSettings(toLanguageVariants: migrationMapping, in: moc)
        migrateSearchLanguageSetting(toLanguageVariants: migrationMapping)
        migrateWikipediaEntities(toLanguageVariants: migrationMapping, in: moc)
        
    }
    
    private func migrateSearchLanguageSetting(toLanguageVariants languageMapping: [String:String]) {
        let defaults = UserDefaults.standard
        if let url = defaults.url(forKey: WMFSearchURLKey),
           let languageCode = url.wmf_language {
            let searchLanguageCode = languageMapping[languageCode] ?? languageCode
            defaults.wmf_setCurrentSearchContentLanguageCode(searchLanguageCode)
            defaults.removeObject(forKey: WMFSearchURLKey)
        }
    }
    
    private func migrateWikipediaEntities(toLanguageVariants languageMapping: [String:String], in moc: NSManagedObjectContext) {
        for (languageCode, languageVariantCode) in languageMapping {
            
            guard let siteURLString = NSURL.wmf_URL(withDefaultSiteAndlanguage: languageCode)?.wmf_databaseKey else {
                assertionFailure("Could not create URL from language code: '\(languageCode)'")
                continue
            }
            
            do {
                // Update ContentGroups
                let contentGroupFetchRequest: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
                contentGroupFetchRequest.predicate = NSPredicate(format: "siteURLString == %@", siteURLString)
                let groups = try moc.fetch(contentGroupFetchRequest)
                for group in groups {
                    group.variant = languageVariantCode
                }
                
                // Update Articles and Gather Keys
                var articleKeys: Set<String> = []
                let articleFetchRequest: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                articleFetchRequest.predicate = NSPredicate(format: "key BEGINSWITH %@", siteURLString)
                let articles = try moc.fetch(articleFetchRequest)
                for article in articles {
                    article.variant = languageVariantCode
                    if let key = article.key {
                        articleKeys.insert(key)
                    }
                }

                // Update Reading List Entries
                let entryFetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
                entryFetchRequest.predicate = NSPredicate(format: "articleKey IN %@", articleKeys)
                let entries = try moc.fetch(entryFetchRequest)
                for entry in entries {
                    entry.variant = languageVariantCode
                }
            } catch let error {
                DDLogError("Error migrating articles to variant '\(languageVariantCode)': \(error)")
            }
        }
        
        if moc.hasChanges {
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving articles and readling list entry variant migrations: \(error)")
            }
        }
    }
}
