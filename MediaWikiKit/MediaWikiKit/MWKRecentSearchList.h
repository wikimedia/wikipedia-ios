
#import "MWKList.h"
#import "MWKRecentSearchEntry.h"
#import "MWKTitle.h"

@class MWKDataStore;

@interface MWKRecentSearchList : MWKList<MWKRecentSearchEntry*, NSString*>

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

- (NSArray*)dataExport;

@end
