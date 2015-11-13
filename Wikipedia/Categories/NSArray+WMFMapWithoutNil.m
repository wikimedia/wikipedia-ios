//
//  NSArray+WMFMapWithoutNil.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/13/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSArray+WMFMapWithoutNil.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (WMFMapWithoutNil)

- (NSArray*)wmf_mapAndRejectNil:(id _Nullable (^ _Nonnull)(id _Nonnull obj))flatMap {
    if (!flatMap) {
        return self;
    }
    return [self bk_reduce:[[NSMutableArray alloc] initWithCapacity:self.count]
                 withBlock:^id (NSMutableArray* sum, id obj) {
        id result = flatMap(obj);
        if (result) {
            [sum addObject:result];
        }
        return sum;
    }];
}

@end

NS_ASSUME_NONNULL_END
