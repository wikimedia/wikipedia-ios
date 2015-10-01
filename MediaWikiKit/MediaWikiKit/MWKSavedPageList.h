
#import "MWKList.h"
#import "MWKSavedPageEntry.h"
#import "MWKTitle.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : MWKList<MWKSavedPageEntry*, MWKTitle*>

/**
 *  Create saved page list and connect with data store.
 *  Will import any saved data from the data store on initialization
 *
 *  @param dataStore The data store to use for retrival and saving
 *
 *  @return The saved page list
 */
- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

- (MWKSavedPageEntry* __nullable)entryForListIndex:(MWKTitle*)title;
- (MWKSavedPageEntry*)           mostRecentEntry;

- (BOOL)isSaved:(MWKTitle*)title;

/**
 * Toggle the save state for `title`.
 *
 * @param title Title to toggle state for, either saving or un-saving it.
 */
- (void)toggleSavedPageForTitle:(MWKTitle*)title;

/**
 *  Add a saved page
 *
 *  @param title The title of the page to add
 */
- (void)addSavedPageWithTitle:(MWKTitle*)title;

- (NSArray*)dataExport;

@end

NS_ASSUME_NONNULL_END
