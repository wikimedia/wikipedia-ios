#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>

NS_ASSUME_NONNULL_BEGIN

@interface YapDatabaseConnection (WMFExtensions)

- (nullable id)wmf_readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction* _Nonnull transaction))block;

- (void)wmf_readInViewWithName:(NSString*)viewName withBlock:(void (^)(YapDatabaseReadTransaction* _Nonnull transaction, YapDatabaseViewTransaction* _Nonnull view))block;

- (nullable id)wmf_readAndReturnResultsInViewWithName:(NSString*)viewName withBlock:(id (^)(YapDatabaseReadTransaction* _Nonnull transaction, YapDatabaseViewTransaction* _Nonnull view))block;

- (void)wmf_readWriteAndReturnUpdatedKeysInViewWithName:(NSString*)viewName withBlock:(NSArray<NSString*>* (^)(YapDatabaseReadWriteTransaction* _Nonnull transaction, YapDatabaseViewTransaction* _Nonnull view))block;

@end

NS_ASSUME_NONNULL_END