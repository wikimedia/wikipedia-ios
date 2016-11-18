#import "WMFContentGroupDataStore.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseViewMappings+WMFMappings.h"

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore ()

@property (nonatomic, strong) MWKDataStore *dataStore;

@end

@implementation WMFContentGroupDataStore

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - section access

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull section, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return;
    }
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        block(section, stop);
    }];
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError || !contentGroups) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return @[];
    }
    return contentGroups;
}

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSArray<WMFContentGroup *> *contentGroups = [self contentGroupsOfKind:kind];
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        block(section, stop);
    }];
}

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)URL {
    NSParameterAssert(URL);
    if (!URL){
        return nil;
    }
    
    NSString *key = [WMFContentGroup databaseKeyForURL:URL];
    if (!key) {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind{
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.midnightUTCDate];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.midnightUTCDate];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return contentGroups;
}

#pragma mark - section add / remove

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    WMFContentGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"WMFContentGroup" inManagedObjectContext:self.dataStore.viewContext];
    group.date = date;
    group.midnightUTCDate = date.midnightUTCDate;
    group.contentGroupKind = kind;
    group.siteURLString = siteURL.absoluteString;
    group.content = associatedContent;
    
    if (customizationBlock) {
        customizationBlock(group);
    }
    
    [group updateKey];
    [group updateContentType];
    [group updateDailySortPriority];
    
    return group;
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent {
    return [self createGroupOfKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent customizationBlock:NULL];
}

- (void)addContentGroup:(WMFContentGroup *)group associatedContent:(NSArray<NSCoding> *)content {
    group.content = content;
}

- (void)removeContentGroup:(WMFContentGroup *)group {
    NSParameterAssert(group);
    [self.dataStore.viewContext deleteObject:group];
}

- (void)removeContentGroups:(NSArray<WMFContentGroup *> *)contentGroups {
    for (WMFContentGroup *group in contentGroups) {
        [self.dataStore.viewContext deleteObject:group];
    }
}

- (BOOL)save:(NSError **)saveError {
    return [self.dataStore save:saveError];
}

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys {
    NSFetchRequest *request = [WMFContentGroup fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key IN %@", keys];
    NSError *fetchError = nil;
    NSArray<WMFContentGroup *> *groups = [self.dataStore.viewContext executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups for deletion: %@", fetchError);
        return;
    }
    [self removeContentGroups:groups];
}

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind {
    NSArray *groups = [self contentGroupsOfKind:kind];
    [self removeContentGroups:groups];
}

@end

NS_ASSUME_NONNULL_END
