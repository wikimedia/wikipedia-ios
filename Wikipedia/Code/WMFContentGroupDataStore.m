#import "WMFContentGroupDataStore.h"

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

- (void)enumerateContentGroupsInManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull section, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return;
    }
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind sortedByDescriptors:(nullable NSArray *)sortDescriptors inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    fetchRequest.sortDescriptors = sortDescriptors;
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError || !contentGroups) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return @[];
    }
    return contentGroups;
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)sortKey ascending:(BOOL)ascending inManagedObjectContext:(NSManagedObjectContext *)moc {
    return [self contentGroupsOfKind:kind sortedByDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending]] inManagedObjectContext:moc];
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc {
    return [self contentGroupsOfKind:kind sortedByDescriptors:nil inManagedObjectContext:moc];
}

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)key ascending:(BOOL)ascending inManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSArray<WMFContentGroup *> *contentGroups = [self contentGroupsOfKind:kind sortedByKey:key ascending:ascending inManagedObjectContext:moc];
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSArray<WMFContentGroup *> *contentGroups = [self contentGroupsOfKind:kind inManagedObjectContext:moc];
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSParameterAssert(URL);
    if (!URL) {
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
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)url   inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@ && siteURLString == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate, url.absoluteString];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate];
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return contentGroups;
}

#pragma mark - section add / remove

- (nullable WMFContentGroup *)createGroupForURL:(nullable NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    WMFContentGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"WMFContentGroup" inManagedObjectContext:moc];
    group.date = date;
    group.midnightUTCDate = date.wmf_midnightUTCDateFromLocalDate;
    group.contentGroupKind = kind;
    group.siteURLString = siteURL.absoluteString;
    group.content = associatedContent;

    if (customizationBlock) {
        customizationBlock(group);
    }

    if (URL) {
        group.URL = URL;
    } else {
        [group updateKey];
    }
    [group updateContentType];
    [group updateDailySortPriority];

    return group;
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    return [self createGroupForURL:nil ofKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent inManagedObjectContext:moc customizationBlock:customizationBlock];
}

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {

    WMFContentGroup *group = [self contentGroupForURL:URL inManagedObjectContext:moc];
    if (group) {
        group.date = date;
        group.midnightUTCDate = date.wmf_midnightUTCDateFromLocalDate;
        group.contentGroupKind = kind;
        group.content = associatedContent;
        group.siteURLString = siteURL.absoluteString;
        if (customizationBlock) {
            customizationBlock(group);
        }
    } else {
        group = [self createGroupForURL:URL ofKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent inManagedObjectContext:moc customizationBlock:customizationBlock];
    }

    return group;
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    return [self createGroupOfKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent inManagedObjectContext:moc customizationBlock:NULL];
}

- (void)removeContentGroup:(WMFContentGroup *)group inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSParameterAssert(group);
    [moc deleteObject:group];
}

- (void)removeContentGroups:(NSArray<WMFContentGroup *> *)contentGroups inManagedObjectContext:(NSManagedObjectContext *)moc {
    for (WMFContentGroup *group in contentGroups) {
        [moc deleteObject:group];
    }
}

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys inManagedObjectContext:(NSManagedObjectContext *)moc{
    NSFetchRequest *request = [WMFContentGroup fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key IN %@", keys];
    NSError *fetchError = nil;
    NSArray<WMFContentGroup *> *groups = [moc executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups for deletion: %@", fetchError);
        return;
    }
    [self removeContentGroups:groups inManagedObjectContext:moc];
}

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSArray *groups = [self contentGroupsOfKind:kind inManagedObjectContext:moc];
    [self removeContentGroups:groups inManagedObjectContext:moc];
}

- (void)performBlockOnImportContext:(nonnull void (^)(NSManagedObjectContext *moc))block {
    NSManagedObjectContext *moc = self.dataStore.feedImportContext;
    [moc performBlock:^{
        block(moc);
    }];
}

@end

NS_ASSUME_NONNULL_END
