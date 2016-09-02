#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFYapDatabaseUpdatedItemKeys = @"WMFYapDatabaseUpdatedItemKeys";

@implementation YapDatabaseReadWriteTransaction (WMFCustomNotifications)

- (void)wmf_setUpdatedItemKeys:(nullable NSArray<NSString *> *)keys {
    NSDictionary *transactionExtendedInfo = @{WMFYapDatabaseUpdatedItemKeys: keys};
    self.yapDatabaseModifiedNotificationCustomObject = transactionExtendedInfo;
}

@end

@implementation NSNotification (WMFCustomNotifications)

- (nullable NSArray *)wmf_updatedItemKeys {
    NSDictionary *transactionExtendedInfo = self.userInfo[YapDatabaseCustomKey];
    NSArray *updatedKeys = transactionExtendedInfo[WMFYapDatabaseUpdatedItemKeys];
    return updatedKeys;
}

@end

NS_ASSUME_NONNULL_END
