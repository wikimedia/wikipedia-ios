#import <WMF/NSIndexSet+BKReduce.h>

@implementation NSIndexSet (BKReduce)

- (id)wmf_reduce:(id)acc withBlock:(id (^)(id acc, NSUInteger idx))reducer {
    if (!reducer) {
        return acc;
    } else if (!acc) {
        return nil;
    }
    __block id result = acc;
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        result = reducer(acc, idx);
    }];
    return result;
}

@end
