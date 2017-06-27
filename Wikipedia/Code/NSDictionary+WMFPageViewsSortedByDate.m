#import <WMF/NSDictionary+WMFPageViewsSortedByDate.h>
#import <WMF/NSArray+WMFMapping.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>

@implementation NSDictionary (WMFPageViewsSortedByDate)

- (NSArray<NSNumber *> *)wmf_pageViewsSortedByDate {
    NSArray *keys = self.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        if ([obj1 isKindOfClass:[NSString class]]) {
            obj1 = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:obj1];
        }
        if ([obj2 isKindOfClass:[NSString class]]) {
            obj2 = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:obj2];
        }
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
