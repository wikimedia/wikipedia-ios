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

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

- (BOOL)isSaved:(NSURL *)url;

#pragma mark - Update Methods

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
 *  Remove all history entries
 */
- (void)removeAllEntries;

#pragma mark - Migration

- (void)migrateLegacyDataIfNeeded;


@end

NS_ASSUME_NONNULL_END
