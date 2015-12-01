
#import "MWKList.h"
#import "MWKRecentSearchEntry.h"
#import "MWKTitle.h"
#import "MWKDataStoreList.h"

@class MWKDataStore;

@interface MWKRecentSearchList : MWKList<MWKRecentSearchEntry*, NSString*>
    < MWKDataStoreList >

- (NSArray*)dataExport;

@end
