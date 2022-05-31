import Foundation
import CocoaLumberjackSwift

/* Whenever a language that previously did not have variants becomes a language with variants, a migration must happen.
 *
 * There are two parts to the migration:
 *      1. Updating persisted items like settings and Core Data records
 *      2. Presenting alerts to the user to make them aware of the new variants
 *
 * 1. Migrating persistent items
 * The first part of this process updates the various settings and user defaults that reference languages and ensure
 * that the correct language variant is set. So, a value such as "zh" for Chinese is replaced with a variant such as "zh-hans".
 *
 * Note that once a language is converted, the 'plain' language code is a valid value meaning to use the 'mixed'
 * content for that site. This is the content as entered into that site without converting to any variant.
 * Because the plain language code means one thing before migration (the language itself) and another thing after
 * migration (the mixed or untransformed variant of the language), migration should only happen once for a given
 * language.
 *
 * If additional languages add variants in the future, a new library version should be used and a new entry mapping the
 * library version to the newly variant-aware languages should be added to -newlyAddedVariantLanguageCodes(for:).
 * The migration code itself should call migrateToLanguageVariants(for:in:) with the new library version.
 *
 *
 * 2. Presenting informational alerts
 * When migrating to use language variants, if the user's preferred languages include languages which have
 * received variant support, an alert is presented to tell the user about variants. An alert is only presented for
 * newly variant-aware languges that also are preferred languages of the user. Multiple alerts shown
 * sequentially are possible, but expected to be rare.
 *
 * The method languageCodesNeedingVariantAlerts(since:) returns all language codes requiring a variant alert since the
 * provided library version. Note that while migrating data is done library version by library version, this API can handle
 * multiple library version updates at once. Also note that the method only returns those language codes that are also
 * in the user's list of preferred languages. So, it is expected that this method will return an empty array for a user
 * with no variant-aware languages in their list of preferred languages.
 */

extension MWKDataStore {
    @objc(migrateToLanguageVariantsForLibraryVersion:inManagedObjectContext:)
    public func migrateToLanguageVariants(for libraryVersion: Int, in moc: NSManagedObjectContext) {
        let languageCodes = newlyAddedVariantLanguageCodes(for: libraryVersion)
        
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
        
        // Ensure any settings that currently use 'nb' are updated to use 'no'
        var languageCodeMigrationMapping = migrationMapping
        languageCodeMigrationMapping["nb"] = "no"
        
        languageLinkController.migratePreferredLanguages(toLanguageVariants: languageCodeMigrationMapping, in: moc)
        feedContentController.migrateExploreFeedSettings(toLanguageVariants: languageCodeMigrationMapping, in: moc)
        migrateSearchLanguageSetting(toLanguageVariants: languageCodeMigrationMapping)
        migrateWikipediaEntities(toLanguageVariants: migrationMapping, in: moc)
    }
    
    private func migrateSearchLanguageSetting(toLanguageVariants languageMapping: [String:String]) {
        let defaults = UserDefaults.standard
        if let url = defaults.url(forKey: WMFSearchURLKey),
           let languageCode = url.wmf_languageCode {
            let searchLanguageCode = languageMapping[languageCode] ?? languageCode
            defaults.wmf_setCurrentSearchContentLanguageCode(searchLanguageCode)
            defaults.removeObject(forKey: WMFSearchURLKey)
        }
    }
    
    private func migrateWikipediaEntities(toLanguageVariants languageMapping: [String:String], in moc: NSManagedObjectContext) {
        for (languageCode, languageVariantCode) in languageMapping {
            
            guard let siteURLString = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: languageCode)?.wmf_databaseKey else {
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
                
                // Update Talk Pages
                let talkPageFetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                talkPageFetchRequest.predicate = NSPredicate(format: "key BEGINSWITH %@", siteURLString)
                let talkPages = try moc.fetch(talkPageFetchRequest)
                for talkPage in talkPages {
                    talkPage.variant = languageVariantCode
                    talkPage.forceRefresh = true
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
    
    // Returns any array of language codes of any of the user's preferred languages that have
    // added variant support since the indicated library version. For each language, the user
    // will be informed of variant support for that language via an alert
    @objc public func languageCodesNeedingVariantAlerts(since libraryVersion: Int) -> [String] {
        let addedVariantLanguageCodes = allAddedVariantLanguageCodes(since: libraryVersion)
        guard !addedVariantLanguageCodes.isEmpty else {
            return []
        }
        var uniqueLanguageCodes: Set<String> = []
        return languageLinkController.preferredLanguages
            .map { $0.languageCode }
            .filter { addedVariantLanguageCodes.contains($0) }
            .filter { uniqueLanguageCodes.insert($0).inserted }
    }
    
    // Returns an array of language codes for all languages that have added variant support
    // since the indicated library version. Used to determine all language codes that might
    // need to have an alert presented to inform the user about the added variant support
    private func allAddedVariantLanguageCodes(since libraryVersion: Int) -> [String] {
        guard libraryVersion < MWKDataStore.currentLibraryVersion else {
            return []
        }
        
        var languageCodes: [String] = []
        for version in libraryVersion...MWKDataStore.currentLibraryVersion {
            languageCodes.append(contentsOf: newlyAddedVariantLanguageCodes(for: version))
        }
        return languageCodes
    }
    
    // Returns the language codes for any languages that have added variant support in that library version.
    // Returns an empty array if no languages added variant support
    private func newlyAddedVariantLanguageCodes(for libraryVersion: Int) -> [String] {
        switch libraryVersion {
        case 12: return ["crh", "gan", "iu", "kk", "ku", "sr", "tg", "uz", "zh"]
        default: return []
        }
    }
}

public extension TalkPage {
    var forceRefresh: Bool {
        get {
            
            guard let revisionID = self.revisionId?.intValue else {
                return false
            }
            
            return UserDefaults.standard.talkPageForceRefreshRevisionIDs?.contains(revisionID) ?? false
        }
        set {
            
            guard let revisionID = self.revisionId?.intValue else {
                assertionFailure("Attempting to set forceRefresh on a talk page that has no revisionID.")
                return
            }
            
            var revisionIDs = UserDefaults.standard.talkPageForceRefreshRevisionIDs ?? Set<Int>()
            
            if newValue == true {
                revisionIDs.insert(revisionID)
            } else {
                revisionIDs.remove(revisionID)
            }
            
            UserDefaults.standard.talkPageForceRefreshRevisionIDs = revisionIDs
        }
    }
}
