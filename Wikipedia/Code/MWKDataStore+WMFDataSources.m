#import "MWKDataStore+WMFDataSources.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabase+WMFViews.h"
#import "WMFDatabaseDataSource.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

@interface MWKDataStore (WMFDataSourcesPrivate)

@property (readonly, strong, nonatomic) YapDatabase *database;
@property (readonly, strong, nonatomic) YapDatabaseConnection *articleReferenceReadConnection;
@property (readonly, strong, nonatomic) YapDatabaseConnection *writeConnection;
@property (readonly, nonatomic, strong) NSPointerArray *changeHandlers;

@end

@implementation MWKDataStore (WMFDataSources)

- (void)registerChangeHandler:(id<WMFDatabaseChangeHandler>)handler {
    [self.changeHandlers addPointer:(__bridge void *_Nullable)(handler)];
}

- (WMFDatabaseDataSource *)registeredDataSourceWithMappings:(YapDatabaseViewMappings *)mappings {
    WMFDatabaseDataSource *datasource = [[WMFDatabaseDataSource alloc] initWithReadConnection:self.articleReferenceReadConnection writeConnection:self.writeConnection mappings:mappings];
    [self registerChangeHandler:datasource];
    return datasource;
}

- (id<WMFDataSource>)historyDataSource {
    return [self registeredDataSourceWithMappings:[self.database wmf_ungroupedMappingsWithView:WMFHistorySortedByDateUngroupedView]];
}

- (id<WMFDataSource>)historyGroupedByDateDataSource {
    return [self registeredDataSourceWithMappings:[self.database wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:WMFHistorySortedByDateGroupedByDateView]];
}

- (id<WMFDataSource>)savedDataSource {
    return [self registeredDataSourceWithMappings:[self.database wmf_ungroupedMappingsWithView:WMFSavedSortedByDateUngroupedView]];
}

- (id<WMFDataSource>)blackListDataSource {
    return [self registeredDataSourceWithMappings:[self.database wmf_ungroupedMappingsWithView:WMFBlackListSortedByURLUngroupedView]];
}

- (id<WMFDataSource>)becauseYouReadSeedsDataSource {
    return [self registeredDataSourceWithMappings:[self.database wmf_ungroupedMappingsWithView:WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificantlyViewedAndNotBlacklistedAndNotMainPageView]];
}

@end
