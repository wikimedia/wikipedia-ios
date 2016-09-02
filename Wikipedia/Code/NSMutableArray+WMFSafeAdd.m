#import "NSMutableArray+WMFSafeAdd.h"

@implementation NSMutableArray (WMFMaybeAdd)

- (BOOL)wmf_safeAddObject:(nullable id)object {
    if (object) {
        [self addObject:object];
        return YES;
    }
    return NO;
}

@end
