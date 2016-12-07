#import "NSDictionary+WMFPageViewsSortedByDate.h"

@implementation NSDictionary (WMFPageViewsSortedByDate)

- (NSArray<NSNumber *> *)wmf_pageViewsSortedByDate {
    NSArray *keys = self.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        BOOL obj1IsDate = [obj1 isKindOfClass:[NSDate class]];
        BOOL obj2IsDate = [obj2 isKindOfClass:[NSDate class]];

        if (!obj1IsDate && !obj2IsDate) {
            return NSOrderedSame;
        } else if (!obj2IsDate) {
            return NSOrderedDescending;
        } else if (!obj1IsDate) {
            return NSOrderedAscending;
        }
        return [obj1 compare:obj2];
    }];
    NSArray *numbers = [keys wmf_mapAndRejectNil:^id(id obj) {
        id value = self[obj];
        return [value isKindOfClass:[NSNumber class]] ? value : nil;
    }];
    return numbers;
}

@end
