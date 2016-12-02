#import "WMFContentGroup+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

#pragma mark - Content Group Access

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url;

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)firstGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (BOOL)save:(NSError **)saveError;

#pragma mark - Content Management

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (void)addContentGroup:(WMFContentGroup *)group associatedContent:(NSArray<NSCoding> *)content;

- (void)removeContentGroup:(WMFContentGroup *)group;

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys;

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind;

@end

NS_ASSUME_NONNULL_END
