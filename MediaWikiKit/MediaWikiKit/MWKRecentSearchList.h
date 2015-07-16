
#import "MWKList.h"

@class MWKRecentSearchEntry, MWKDataStore;

@interface MWKRecentSearchList : MWKList

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

/**
 *  Create saved page list and connect with data store.
 *  Will import any saved data from the data store on initialization
 *
 *  @param dataStore The data store to use for retrival and saving
 *
 *  @return The saved page list
 */
- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (MWKRecentSearchEntry*)entryAtIndex:(NSUInteger)index;

/**
 *  Add an entry to the search history
 *
 *  @param entry The entry to add
 *
 *  @return The task. The result is the MWKSavedPageEntry.
 */
- (void)addEntry:(MWKRecentSearchEntry*)entry;


- (NSArray*)dataExport;

@end
