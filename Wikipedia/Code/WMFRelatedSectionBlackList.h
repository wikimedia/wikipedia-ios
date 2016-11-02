#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKHistoryEntry, MWKDataStore;

@interface WMFRelatedSectionBlackList : MTLModel

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly, weak, nonatomic) MWKDataStore *dataStore;

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems;

- (nullable MWKHistoryEntry *)entryForURL:(NSURL *)url;

- (nullable MWKHistoryEntry *)mostRecentEntry;

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry *_Nonnull entry, BOOL *stop))block;

/**
 *  Check if a url is blacklisted
 *
 *  @param url The url to check
 */
- (BOOL)articleURLIsBlackListed:(NSURL *)url;

#pragma mark - Update Methods

/**
 *  Add a url to the black list
 *
 *  @param url The url to add
 */
- (nullable MWKHistoryEntry *)addBlackListArticleURL:(NSURL *)url;

/**
 *  Remove a url to the black list
 *
 *  @param url The url to remove
 */
- (void)removeBlackListArticleURL:(NSURL *)url;

/**
 *  Remove all blacklist items
 */
- (void)removeAllEntries;

@end

NS_ASSUME_NONNULL_END
