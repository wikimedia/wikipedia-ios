
#import <Foundation/Foundation.h>

@class MWKHistoryEntry, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : NSObject

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems;

- (nullable MWKHistoryEntry*)mostRecentEntry;

- (nullable MWKHistoryEntry*)entryForURL:(NSURL*)url;

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry* _Nonnull entry, BOOL* stop))block;

- (BOOL)isSaved:(NSURL*)url;


#pragma mark - Update Methods

/**
 * Toggle the save state for `url`.
 *
 * @param url URL to toggle state for, either saving or un-saving it.
 */
- (void)toggleSavedPageForURL:(NSURL*)url;

/**
 *  Add a saved page
 *
 *  @param title The title of the page to add
 */
- (MWKHistoryEntry*)addSavedPageWithURL:(NSURL*)url;

/**
 *  Remove a saved page
 *
 *  @param url The url of the page to remove
 */
- (void)removeEntryWithURL:(NSURL*)url;

/**
 *  Remove all history entries
 */
- (void)removeAllEntries;


@end

NS_ASSUME_NONNULL_END
