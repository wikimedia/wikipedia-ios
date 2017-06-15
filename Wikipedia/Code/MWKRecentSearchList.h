#import <WMF/MWKList.h>
#import <WMF/MWKRecentSearchEntry.h>
#import "MWKDataStoreList.h"

@class MWKDataStore;

@interface MWKRecentSearchList : MWKList <MWKRecentSearchEntry *, NSString *>
<MWKDataStoreList>

    - (NSArray *)dataExport;

@end
