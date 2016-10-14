#import "MWKDataStore+WMFDataSources.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseViewMappings+WMFMappings.h"
#import "WMFDatabaseDataSource.h"
#import "MWKHistoryEntry+WMFDatabaseViews.h"

@interface MWKDataStore (WMFDataSourcesPrivate)

@property (readonly, nonatomic, strong) NSPointerArray *changeHandlers;

@end

@implementation MWKDataStore (WMFDataSources)

- (WMFDatabaseDataSource *)registeredDataSourceWithMappings:(YapDatabaseViewMappings *)mappings {
    WMFDatabaseDataSource *datasource = [[WMFDatabaseDataSource alloc] initWithReadConnection:self.readConnection writeConnection:self.writeConnection mappings:mappings];
    [self registerChangeHandler:datasource];
    return datasource;
}

- (id<WMFDataSource>)historyDataSource {
    return [self registeredDataSourceWithMappings:[YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFHistorySortedByDateUngroupedView]];
}

- (id<WMFDataSource>)historyGroupedByDateDataSource {
    return [self registeredDataSourceWithMappings:[YapDatabaseViewMappings wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:WMFHistorySortedByDateGroupedByDateView]];
}

- (id<WMFDataSource>)savedDataSource {
    return [self registeredDataSourceWithMappings:[YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFSavedSortedByDateUngroupedView]];
}

- (id<WMFDataSource>)blackListDataSource {
    return [self registeredDataSourceWithMappings:[YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFBlackListSortedByURLUngroupedView]];
}

- (id<WMFDataSource>)becauseYouReadSeedsDataSource {
    return [self registeredDataSourceWithMappings:[YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificantlyViewedAndNotBlacklistedAndNotMainPageView]];
}

@end
