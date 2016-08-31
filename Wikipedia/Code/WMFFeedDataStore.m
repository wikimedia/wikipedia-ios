
#import "WMFFeedDataStore.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseViewMappings+WMFMappings.h"
#import "WMFDatabaseDataSource.h"
#import "WMFExploreSection+WMFDatabaseStorable.h"
#import "WMFExploreSection+WMFDatabaseViews.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedDataStore ()

@end

@implementation WMFFeedDataStore

- (instancetype)initWithDatabase:(YapDatabase *)database
{
    self = [super initWithDatabase:database];
    if (self) {
        [WMFExploreSection registerViewsInDatabase:database];
    }
    return self;
}

#pragma mark - section access

- (void)enumerateSectionsWithBlock:(void (^)(WMFExploreSection *_Nonnull section, BOOL *stop))block{
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[WMFExploreSection databaseCollectionName] usingBlock:^(NSString * _Nonnull key, id  _Nonnull object, BOOL * _Nonnull stop) {
            block(object, stop);
        }];
    }];
}

- (void)enumerateSectionsOfType:(WMFExploreSectionType)type withBlock:(void (^)(WMFExploreSection *_Nonnull section, BOOL *stop))block{
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[MWKHistoryEntry databaseCollectionName] usingBlock:^(NSString * _Nonnull key, WMFExploreSection*  _Nonnull object, BOOL * _Nonnull stop) {
            if(object.type == type){
                block(object, stop);
            }
        }];
    }];
}


- (WMFExploreSection*)moreLikeSectionForArticleURL:(NSURL*)url{
    NSParameterAssert(url.wmf_title);
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        WMFExploreSection *entry = [transaction objectForKey:[WMFExploreSection databaseKeyForURL:url] inCollection:[WMFExploreSection databaseCollectionName]];
        return entry;
    }];
}

- (WMFExploreSection*)sectionForDate:(NSDate*)date siteURL:(NSURL*)siteURL type:(WMFExploreSectionType)type{
    NSParameterAssert(date);
    NSParameterAssert(siteURL);

    NSURL* sectionURL = [WMFExploreSection urlForSiteURL:siteURL date:date type:type];

    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        MWKHistoryEntry *entry = [transaction objectForKey:[WMFExploreSection databaseKeyForURL:sectionURL] inCollection:[WMFExploreSection databaseCollectionName]];
        return entry;
    }];
}



- (nullable NSArray<NSURL*>*)contentURLsForSection:(WMFExploreSection*)section{
    NSArray<NSURL*>* urls = [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        id content = [transaction metadataForKey:[section databaseKey] inCollection:[[section class] databaseCollectionName]];
        return content;
    }];
    NSAssert([urls isKindOfClass:[NSArray class]], @"Content is not an array!");
    
    if([urls count] > 0){
        NSAssert([[urls firstObject] isKindOfClass:[NSURL class]], @"Content item is not a URL!");

    }
    return urls;
}

#pragma mark - section add / remove

- (void)addSection:(WMFExploreSection*)section associatedContentURLs:(nullable NSArray<NSURL*>*)content{
    [self readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction setObject:section forKey:[section databaseKey] inCollection:[[section class] databaseCollectionName] withMetadata:content];
    }];
}

- (void)removeSection:(WMFExploreSection*)section{
    NSParameterAssert(section);
    [self readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction removeObjectForKey:[section databaseKey] inCollection:[WMFExploreSection databaseCollectionName]];
    }];
}


@end

@implementation WMFFeedDataStore (WMFDataSources)

- (id<WMFDataSource>)feedDataSource{
    
    YapDatabaseViewMappings* mappings = [YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFBlackListSortedByURLUngroupedView];
    
    WMFDatabaseDataSource *datasource = [[WMFDatabaseDataSource alloc] initWithReadConnection:self.readConnection writeConnection:self.writeConnection mappings:mappings];
    [self registerChangeHandler:datasource];
    return datasource;
}


@end


NS_ASSUME_NONNULL_END
