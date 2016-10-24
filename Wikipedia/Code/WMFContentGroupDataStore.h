#import "WMFBaseDataStore.h"
#import "WMFDataSource.h"

@class WMFContentGroup;
@class WMFRelatedPagesContentGroup;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroupDataStore : WMFBaseDataStore

#pragma mark - Content Group Access

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url;

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(NSString *)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (nullable WMFContentGroup *)firstGroupOfKind:(NSString *)kind;

- (nullable WMFContentGroup *)firstGroupOfKind:(NSString *)kind forDate:(NSDate *)date;

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(NSString *)kind forDate:(NSDate *)date;

#pragma mark - Content Access

/*
 * The content for the given group.
 * The content class is defined by WMFContentGroup.contentType
 */
- (nullable NSArray<NSCoding> *)contentForContentGroup:(WMFContentGroup *)group;

#pragma mark - Content Management

- (void)addContentGroup:(WMFContentGroup *)group associatedContent:(NSArray<NSCoding> *)content;

- (void)removeContentGroup:(WMFContentGroup *)group;

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys;

- (void)removeAllContentGroupsOfKind:(NSString *)kind;

@end

@interface WMFContentGroupDataStore (WMFDataSources)

- (id<WMFDataSource>)contentGroupDataSource;

@end

NS_ASSUME_NONNULL_END
