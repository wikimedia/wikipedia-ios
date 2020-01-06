@import Foundation;
#import <CoreData/CoreData.h>

@class MWKDataStore;
@class WMFArticle;

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryList : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly, weak, nonatomic) MWKDataStore *dataStore;

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems;

- (nullable WMFArticle *)mostRecentEntry;
- (nullable WMFArticle *)mostRecentEntryInManagedObjectContext:(NSManagedObjectContext *)context;

- (nullable WMFArticle *)entryForURL:(NSURL *)url;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

#pragma mark - Update Methods

/**
 *  Add a page to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param url The url of the page to add
 */
- (nullable WMFArticle *)addPageToHistoryWithURL:(NSURL *)url;

/**
 *  Add pages to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param URLs The urls of the pages to add
 */
- (void)addPagesToHistoryWithURLs:(NSArray<NSURL *> *)URLs;

/**
 *  Save the scroll position of a page.
 *
 *  @param fragment     The fragment to save
 *  @param scrollPosition The scroll position to save
 *  @param url          The url of the page
 *
 */
- (void)setFragment:(nullable NSString *)fragment scrollPosition:(double)scrollPosition onPageInHistoryWithURL:(NSURL *)url;

/**
 *  Sets the history entry to be "significantly viewed"
 *  This denotes that a user looked at this title for a period of time to indicate interest
 *
 *  @param url The url to set to significantly viewed
 */
- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL *)url;

/**
 *  Remove a page from the user history
 *
 *  @param url The url of the page to remove
 */
- (void)removeEntryWithURL:(NSURL *)url;

/**
 *  Remove all history entries
 */
- (void)removeAllEntries;

@end

NS_ASSUME_NONNULL_END
