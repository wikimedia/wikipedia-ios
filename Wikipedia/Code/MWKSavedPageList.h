@import Foundation;
@class WMFArticle, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly, weak, nonatomic) MWKDataStore *dataStore;

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems;

- (nullable WMFArticle *)mostRecentEntry;

/**
 * Get n last entries that have lead images.
 *
 * @param limit to specify the number of returned articles.
 * @return array or n articles with lead images.
 */

- (nullable NSArray<WMFArticle *> *)entriesWithLeadImages:(NSInteger)limit;

- (nullable WMFArticle *)entryForURL:(NSURL *)url;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

- (BOOL)isSaved:(NSURL *)url;

#pragma mark - Update Methods

/**
 * Toggle the save state for the article with `key`.
 *
 * @param key to toggle state for, either saving or un-saving it. Key is a standardized version of the article URL obtained by the key property on WMFArticle or from a URL with wmf_articleDatabaseKey
 * @return whether or not the key is now saved
 */
- (BOOL)toggleSavedPageForKey:(NSString *)key;

/**
 * Toggle the save state for `url`.
 *
 * @param url URL to toggle state for, either saving or un-saving it.
 * @return whether or not the URL is now saved
 */
- (BOOL)toggleSavedPageForURL:(NSURL *)url;

/**
 *  Add a saved page
 *
 *  @param url The url of the page to add
 */
- (void)addSavedPageWithURL:(NSURL *)url;

/**
 *  Remove a saved page
 *
 *  @param url The url of the page to remove
 */
- (void)removeEntryWithURL:(NSURL *)url;

/**
 *  Remove entries with given urls
 */
- (void)removeEntriesWithURLs:(NSArray<NSURL *> *)urls;

/**
 *  Remove all history entries
 */
- (void)removeAllEntries;

#pragma mark - Migration

- (void)migrateLegacyDataIfNeeded;

@end

NS_ASSUME_NONNULL_END
