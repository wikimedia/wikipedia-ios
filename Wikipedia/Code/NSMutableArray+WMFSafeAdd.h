@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray <ObjectType>
(WMFMaybeAdd)

    - (BOOL)wmf_safeAddObject : (nullable ObjectType)object;

@end

NS_ASSUME_NONNULL_END
