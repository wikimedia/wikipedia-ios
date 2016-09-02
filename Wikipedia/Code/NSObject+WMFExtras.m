#import "NSObject+WMFExtras.h"

@implementation NSObject (WMFExtras)

- (BOOL)isNull {
    return [self isKindOfClass:[NSNull class]];
}

- (BOOL)isDict {
    return [self isKindOfClass:[NSDictionary class]];
}

@end
