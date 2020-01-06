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

- (nullable WMFArticle *)entryForURL:(NSURL *)url;
- (nullable WMFArticle *)entryForKey:(NSString *)key;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

- (BOOL)isSaved:(NSURL *)url;

#pragma mark - Update Methods

/**
 * Toggle the save state for the article with `key`.
 *
 * @param key to toggle state for, either saving or un-saving it. Key is a standardized version of the article URL obtained by the key property on WMFArticle or from a URL with wmf_databaseKey
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

@end

NS_ASSUME_NONNULL_END
