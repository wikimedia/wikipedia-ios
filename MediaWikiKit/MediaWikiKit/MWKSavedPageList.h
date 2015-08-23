
#import "MWKList.h"

@class MWKTitle;
@class MWKSavedPageEntry;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : MWKList

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

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index;
- (MWKSavedPageEntry* __nullable)entryForTitle:(MWKTitle*)title;
- (MWKSavedPageEntry*)mostRecentEntry;

- (NSUInteger)indexForEntry:(MWKSavedPageEntry*)entry;

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
 *  Add an entry to the the user saved pages
 *  Use this method if you needed to create an entry directly.
 *
 *  @param entry The entry to add
 */
- (void)addEntry:(MWKSavedPageEntry*)entry;

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
