#import "WMFContentGroup+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

#pragma mark - Import Context

- (void)performBlockOnImportContext:(nonnull void (^)(NSManagedObjectContext *moc))block;

#pragma mark - Content Management

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent inManagedObjectContext:(NSManagedObjectContext *)moc customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)removeContentGroup:(WMFContentGroup *)group inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc;

#pragma mark - Content Group Access

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)enumerateContentGroupsInManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)key ascending:(BOOL)ascending inManagedObjectContext:(NSManagedObjectContext *)moc withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc;

@end

NS_ASSUME_NONNULL_END
