#import "WMFContentGroupDataStore.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseViewMappings+WMFMappings.h"
#import "WMFDatabaseDataSource.h"
#import "WMFContentGroup.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "WMFContentGroup+WMFDatabaseViews.h"

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore ()

@end

@implementation WMFContentGroupDataStore

#pragma mark - section access

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull section, BOOL *stop))block {
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[WMFContentGroup databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, id _Nonnull object, BOOL *_Nonnull stop) {
                                                  block(object, stop);
                                              }];
    }];
}

- (void)enumerateContentGroupsOfKind:(NSString *)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[WMFContentGroup databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, WMFContentGroup *_Nonnull object, BOOL *_Nonnull stop) {
                                                  if ([[[object class] kind] isEqualToString:kind]) {
                                                      block(object, stop);
                                                  }
                                              }];
    }];
}

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url {
    NSParameterAssert(url);
    if(!url){
        return nil;
    }
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        WMFContentGroup *group = [transaction objectForKey:[WMFContentGroup databaseKeyForURL:url] inCollection:[WMFContentGroup databaseCollectionName]];
        return group;
    }];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(NSString *)kind{
    
    __block WMFContentGroup *found = nil;
    [self enumerateContentGroupsOfKind:kind
                             withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                 found = (id)group;
                                 *stop = YES;
                             }];
    return found;
}


- (nullable WMFContentGroup *)firstGroupOfKind:(NSString *)kind forDate:(NSDate *)date {

    __block WMFContentGroup *found = nil;
    [self enumerateContentGroupsOfKind:kind
                             withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                 if ([[group.date dateAtStartOfDay] isEqualToDate:[date dateAtStartOfDay]]) {
                                     found = (id)group;
                                     *stop = YES;
                                 }
                             }];
    return found;
}

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(NSString *)kind forDate:(NSDate *)date {

    NSMutableArray *found = [NSMutableArray array];
    [self enumerateContentGroupsOfKind:kind
                             withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                 if ([[group.date dateAtStartOfDay] isEqualToDate:[date dateAtStartOfDay]]) {
                                     [found addObject:group];
                                 }
                             }];
    return found;
}

- (nullable NSArray<id> *)contentForContentGroup:(WMFContentGroup *)group {
    NSArray<NSURL *> *content = [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        id content = [transaction metadataForKey:[group databaseKey] inCollection:[[group class] databaseCollectionName]];
        return content;
    }];

    if ([content count] > 0) {
        NSAssert([content isKindOfClass:[NSArray class]], @"Content is not an array!");
    }
    return content;
}

#pragma mark - section add / remove

- (void)addContentGroup:(WMFContentGroup *)group associatedContent:(NSArray<NSCoding> *)content {
    [self asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [transaction setObject:group forKey:[group databaseKey] inCollection:[[group class] databaseCollectionName] withMetadata:content];
    }];
}

- (void)removeContentGroup:(WMFContentGroup *)group {
    NSParameterAssert(group);
    [self asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [transaction removeObjectForKey:[group databaseKey] inCollection:[WMFContentGroup databaseCollectionName]];
    }];
}

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys {
    [self asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [transaction removeObjectsForKeys:keys inCollection:[WMFContentGroup databaseCollectionName]];
    }];
}

- (void)removeAllContentGroupsOfKind:(NSString *)kind {
    NSMutableArray *keys = [NSMutableArray array];
    [self enumerateContentGroupsOfKind:kind
                             withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                 [keys addObject:[group databaseKey]];
                             }];

    [self removeContentGroupsWithKeys:keys];
}

@end

@implementation WMFContentGroupDataStore (WMFDataSources)

- (id<WMFDataSource>)contentGroupDataSource {

    YapDatabaseViewMappings *mappings = [YapDatabaseViewMappings wmf_ungroupedMappingsWithView:WMFContentGroupsSortedByDateView];

    WMFDatabaseDataSource *datasource = [[WMFDatabaseDataSource alloc] initWithReadConnection:self.readConnection writeConnection:self.writeConnection mappings:mappings];
    [self registerChangeHandler:datasource];
    return datasource;
}

@end

NS_ASSUME_NONNULL_END
