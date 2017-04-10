#import "WMFContentGroup+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;
- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind;
- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, NSManagedObjectContext *_Nonnull moc, BOOL *stop))block;
- (void)removeContentGroup:(WMFContentGroup *)group inManagedObjectContext:(NSManagedObjectContext *)moc;

@end

NS_ASSUME_NONNULL_END
