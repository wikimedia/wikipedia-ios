
#import "MWKList.h"
#import "MWKSavedPageEntry.h"

@class MWKTitle;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : MWKList<MWKSavedPageEntry*>

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

- (MWKSavedPageEntry* __nullable)entryForTitle:(MWKTitle*)title;
- (MWKSavedPageEntry*)           mostRecentEntry;

- (BOOL)isSaved:(MWKTitle*)title;

/**
 * Change properties on a specific entry without changing its order in the list
 * @param title     The title of the entry you want to change.
 * @param update    Block which mutates the entry matching that title, if one was found, then returns
 *                  `YES` if the entry was mutated (and the list should be changed the next time `save` is
 *                  called, or `NO` if no change occurred.
 */
- (void)updateEntryWithTitle:(MWKTitle*)title update:(BOOL (^)(MWKSavedPageEntry*))update;

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

/**
 *  Remove a saved page task
 *
 *  @param title The title of the page to remove
 */
- (void)removeSavedPageWithTitle:(MWKTitle*)title;

/**
 *  Remove all saved pages
 */
- (void)removeAllSavedPages;

- (NSArray*)dataExport;

@end

NS_ASSUME_NONNULL_END
