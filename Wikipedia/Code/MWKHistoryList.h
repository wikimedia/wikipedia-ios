#import "MWKList.h"
#import "MWKHistoryEntry.h"
#import "MWKDataStoreList.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const MWKHistoryListDidUpdateNotification;

@interface MWKHistoryList : MWKList<MWKHistoryEntry*, NSURL*>
    < MWKDataStoreList >

- (nullable MWKHistoryEntry*)mostRecentEntry;

- (nullable MWKHistoryEntry*)entryForURL:(NSURL*)url;

/**
 *  Add a page to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param url           The url of the page to add
 */
- (MWKHistoryEntry*)addPageToHistoryWithURL:(NSURL*)url;

/**
 *  Save the scroll position of a page.
 *
 *  @param scrollposition The scroll position to save
 *  @param url          The url of the page
 *
 *  @return The task. The result is the MWKHistoryEntry.
 */
- (void)setPageScrollPosition:(CGFloat)scrollposition onPageInHistoryWithURL:(NSURL*)url;

/**
 *  Sets the history entry to be "significantly viewed"
 *  This denotes that a user looked at this title for a period of time to indicate interest
 *
 *  @param url The url to set to significantly viewed
 */
- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL*)url;

/**
 *  Remove the given history entries from the history.
 *
 *  @param historyEntries An array of instances of MWKHistoryEntry
 */
- (void)removeEntriesFromHistory:(NSArray*)historyEntries;

- (NSArray*)dataExport;

- (void)prune;

@end

NS_ASSUME_NONNULL_END
