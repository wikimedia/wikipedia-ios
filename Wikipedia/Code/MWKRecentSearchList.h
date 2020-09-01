#import <WMF/MWKList.h>
#import <WMF/MWKRecentSearchEntry.h>
#import <WMF/MWKDataStoreList.h>

@class MWKDataStore;

@interface MWKRecentSearchList : MWKList <MWKRecentSearchEntry *, NSString *>
<MWKDataStoreList>

    - (NSArray *)dataExport;

@end
