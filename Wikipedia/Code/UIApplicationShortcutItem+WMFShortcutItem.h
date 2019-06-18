@import UIKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFIconShortcutTypeSearch;
extern NSString *const WMFIconShortcutTypeContinueReading;
extern NSString *const WMFIconShortcutTypeRandom;
extern NSString *const WMFIconShortcutTypeNearby;

@interface UIApplicationShortcutItem (WMFShortcutItem)

+ (UIApplicationShortcutItem *)wmf_search;
+ (UIApplicationShortcutItem *)wmf_random;
+ (UIApplicationShortcutItem *)wmf_nearby;

@end

NS_ASSUME_NONNULL_END
