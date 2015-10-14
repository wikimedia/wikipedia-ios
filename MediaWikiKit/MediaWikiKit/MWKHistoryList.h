
#import "MWKList.h"
#import "MWKHistoryEntry.h"
#import "MWKTitle.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryList : MWKList<MWKHistoryEntry*, MWKTitle*>

/**
 *  Create history list and connect with data store.
 *  Will import any saved data from the data store on initialization
 *
 *  @param dataStore The data store to use for retrival and saving
 *
 *  @return The history list
 */
- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

@property (nonatomic, weak, readonly) MWKDataStore* dataStore;

- (nullable MWKHistoryEntry*)mostRecentEntry;

- (nullable MWKHistoryEntry*)entryForTitle:(MWKTitle*)title;

/**
 *  Add a page to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param title           The title of the page to add
 *  @param discoveryMethod The method of discovery. MWKHistoryDiscoveryMethodUnknown is ignored if updating an existing
 *                         entry.
 */
- (MWKHistoryEntry*)addPageToHistoryWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

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
 *  Remove the given history entries from the history.
 *
 *  @param historyEntries An array of instances of MWKHistoryEntry
 */
- (void)removeEntriesFromHistory:(NSArray*)historyEntries;

- (NSArray*)dataExport;

@end

NS_ASSUME_NONNULL_END

