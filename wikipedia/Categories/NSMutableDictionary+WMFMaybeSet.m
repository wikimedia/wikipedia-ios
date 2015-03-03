#import "NSMutableDictionary+WMFMaybeSet.h"

@implementation NSMutableDictionary (WMFMaybeSet)

- (BOOL)wmf_maybeSetObject:(id)obj forKey:(id<NSCopying>)key {
    if (obj) {
        self[key] = obj;
        return YES;
    } else {
        return NO;
    }
}

@end
