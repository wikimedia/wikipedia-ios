#import "YapDatabaseConnection+WMFExtensions.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YapDatabaseConnection (WMFExtensions)

- (nullable id)wmf_readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction))block {
    __block id results = nil;
    NSParameterAssert(block);
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        results = block(transaction);
    }];
    return results;
}

- (void)wmf_readInViewWithName:(NSString *)viewName withBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    NSParameterAssert(block);
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        YapDatabaseViewTransaction *view = [transaction ext:viewName];
        NSParameterAssert(view);
        block(transaction, view);
    }];
}

- (nullable id)wmf_readAndReturnResultsInViewWithName:(NSString *)viewName withBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    __block id results = nil;
    NSParameterAssert(block);
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        YapDatabaseViewTransaction *view = [transaction ext:viewName];
        NSParameterAssert(view);
        results = block(transaction, view);
    }];
    return results;
}

- (void)wmf_readWriteAndReturnUpdatedKeysInViewWithName:(NSString *)viewName withBlock:(NSArray<NSString *> * (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    NSParameterAssert(block);
    [self readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        YapDatabaseViewTransaction *view = [transaction ext:viewName];
        NSParameterAssert(view);
        NSArray *keys = block(transaction, view);
        [transaction wmf_setUpdatedItemKeys:keys];
    }];
}

@end

NS_ASSUME_NONNULL_END
