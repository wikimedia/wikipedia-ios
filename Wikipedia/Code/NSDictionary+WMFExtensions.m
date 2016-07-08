
#import "NSDictionary+WMFExtensions.h"

@implementation NSDictionary (WMFExtensions)

- (BOOL)containsNullObjects {
    NSNull* null = [self bk_match:^BOOL (id key, id obj) {
        return [obj isKindOfClass:[NSNull class]];
    }];
    return (null != nil);
}

@end
