#import <WMF/NSArray+WMFMapping.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (WMFMapping)

- (NSArray *)wmf_strictMap:(id (^)(id obj))block {
    NSParameterAssert(block != nil);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        NSParameterAssert(value != nil);
        if (!value) {
            value = [NSNull null];
        }
        [result addObject:value];
    }];

    return result;
}

- (NSArray *)wmf_mapAndRejectNil:(id _Nullable (^_Nonnull)(id _Nonnull obj))flatMap {
    if (!flatMap) {
        return self;
    }
    return [self wmf_reduce:[[NSMutableArray alloc] initWithCapacity:self.count]
                  withBlock:^id(NSMutableArray *sum, id obj) {
                      id result = flatMap(obj);
                      if (result) {
                          [sum addObject:result];
                      }
                      return sum;
                  }];
}

@end

NS_ASSUME_NONNULL_END
