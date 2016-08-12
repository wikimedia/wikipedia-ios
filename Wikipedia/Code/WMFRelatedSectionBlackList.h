
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKHistoryEntry, MWKDataStore;

@interface WMFRelatedSectionBlackList : MTLModel

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

#pragma mark - Convienence Methods

- (nullable MWKHistoryEntry*)entryForURL:(NSURL*)url;

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry* _Nonnull entry, BOOL* stop))block;

#pragma mark - Update Methods

/**
 *  Add a url to the black list
 *
 *  @param url The url to add
 */
- (MWKHistoryEntry*)addBlackListArticleURL:(NSURL*)url;

/**
 *  Remove a url to the black list
 *
 *  @param url The url to remove
 */
- (void)removeBlackListArticleURL:(NSURL*)url;

/**
 *  Check if a url is blacklisted
 *
 *  @param url The url to check
 */
- (BOOL)articleURLIsBlackListed:(NSURL*)url;


@end

NS_ASSUME_NONNULL_END

