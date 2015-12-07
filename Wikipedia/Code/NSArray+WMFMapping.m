
#import "NSArray+WMFMapping.h"

@implementation NSArray (WMFMapping)

- (NSArray*)wmf_strictMap:(id (^)(id obj))block {
    NSParameterAssert(block != nil);

    NSMutableArray* result = [NSMutableArray arrayWithCapacity:self.count];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id value = block(obj);
        NSParameterAssert(value != nil);
        if (!value) {
            value = [NSNull null];
        }
        [result addObject:value];
    }];

    return result;
}

- (NSArray*)wmf_mapRemovingNilElements:(id (^)(id obj))block {
    NSParameterAssert(block != nil);

    NSMutableArray* result = [NSMutableArray arrayWithCapacity:self.count];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];

    return result;
}

@end
