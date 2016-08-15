#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableSet<ObjectType> (WMFMaybeAdd)

- (BOOL)wmf_safeAddObject:(nullable ObjectType)object;

@end

NS_ASSUME_NONNULL_END
