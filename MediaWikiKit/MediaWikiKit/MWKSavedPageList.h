
#import "MWKDataObject.h"

@class MWKTitle;
@class MWKSavedPageEntry;
@class MWKDataStore;
@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSavedPageList : MWKDataObject <NSFastEnumeration>

/**
 *  Observable - observe to get KVO notifications
 */
@property (nonatomic, strong, readonly) NSArray* entries;

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;
@property (readonly, nonatomic, assign) NSUInteger length;
@property (readonly, nonatomic, assign) BOOL dirty;

/**
 *  Create saved page list and connect with data store.
 *  Will import any saved data from the data store on initialization
 *
 *  @param dataStore The data store to use for retrival and saving
 *
 *  @return The saved page list
 */
- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index;
- (NSUInteger)indexForEntry:(MWKSavedPageEntry*)entry;

- (MWKSavedPageEntry* __nullable)entryForTitle:(MWKTitle*)title;
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
 *  Toggle Saved Page status for a title
 *
 *  @param title The title of the page to toggle
 *
 *  @return The task. The result is nil.
 */
- (void)toggleSavedPageForTitle:(MWKTitle*)title;

/**
 *  Add a saved page
 *
 *  @param title The title of the page to add
 *
 *  @return The task. The result is the MWKSavedPageEntry.
 */
- (void)addSavedPageWithTitle:(MWKTitle*)title;

/**
 *  Add an entry to the the user saved pages
 *  Use this method if you needed to create an entry directly.
 *
 *  @param entry The entry to add
 *
 *  @return The task. The result is the MWKSavedPageEntry.
 */
- (void)addEntry:(MWKSavedPageEntry*)entry;

/**
 *  Remove a saved page task
 *
 *  @param title The title of the page to remove
 *
 *  @return The task. The result is nil.
 */
- (void)removeSavedPageWithTitle:(MWKTitle*)title;

/**
 *  Remove all saved pages
 *
 *  @return The task. The result will be nil.
 */
- (void)removeAllSavedPages;

/**
 *  Save changes to data store.
 *
 *  @return The task. Result will be nil.
 */
- (AnyPromise*)save;


@end

NS_ASSUME_NONNULL_END
