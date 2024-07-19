#import <Foundation/Foundation.h>
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

// This method retrieves whichever variant of the article specified by the key is currently saved
// Even if a different article variant is being shown to the user, it is the variant that is actually saved
// that will be removed.
- (nullable WMFArticle *)articleToUnsaveForKey:(NSString *)key;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

- (BOOL)isAnyVariantSaved:(NSURL *)url;

#pragma mark - Update Methods

/**
 * Toggle the save state for the article with `key`.
 *
 * @param key to toggle state for, either saving or un-saving it. Key is a standardized version of the article URL obtained by the key property on WMFArticle or from a URL with wmf_databaseKey
 * @param variant to toggle state for. Variant is a language variant code.
 * @return whether or not the key is now saved
 */
- (BOOL)toggleSavedPageForKey:(NSString *)key variant:(nullable NSString *)variant;

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

@end

NS_ASSUME_NONNULL_END
