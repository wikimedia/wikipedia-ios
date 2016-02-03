
#import "MWKList.h"
#import "MWKHistoryEntry.h"
#import "MWKTitle.h"
#import "MWKDataStoreList.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const MWKHistoryListDidUpdateNotification;

@interface MWKHistoryList : MWKList<MWKHistoryEntry*, MWKTitle*>
    < MWKDataStoreList >

- (nullable MWKHistoryEntry*)mostRecentEntry;

- (nullable MWKHistoryEntry*)entryForTitle:(MWKTitle*)title;

/**
 *  Add a page to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param title           The title of the page to add
 */
- (MWKHistoryEntry*)addPageToHistoryWithTitle:(MWKTitle*)title;

/**
 *  Save the scroll position of a page.
 *
 *  @param scrollposition The scroll position to save
 *  @param title          The title of the page
 *
 *  @return The task. The result is the MWKHistoryEntry.
 */
- (void)setPageScrollPosition:(CGFloat)scrollposition onPageInHistoryWithTitle:(MWKTitle*)title;

/**
 *  Sets the history entry to be "significantly viewed"
 *  This denotes that a user looked at this title for a period of time to indicate interest
 *
 *  @param title The title to set to significantly viewed
 */
- (void)setSignificantlyViewedOnPageInHistoryWithTitle:(MWKTitle*)title;

/**
 *  Remove the given history entries from the history.
 *
 *  @param historyEntries An array of instances of MWKHistoryEntry
 */
- (void)removeEntriesFromHistory:(NSArray*)historyEntries;

- (NSArray*)dataExport;

@end

NS_ASSUME_NONNULL_END
