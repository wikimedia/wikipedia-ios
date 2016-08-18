#import "MWKDataStore.h"
#import "WMFDataSource.h"

@interface MWKDataStore (WMFDataSources)

- (id<WMFDataSource>)historyDataSource;

- (id<WMFDataSource>)historyGroupedByDateDataSource;

- (id<WMFDataSource>)savedDataSource;

- (id<WMFDataSource>)blackListDataSource;

- (id<WMFDataSource>)becauseYouReadSeedsDataSource;

@end
