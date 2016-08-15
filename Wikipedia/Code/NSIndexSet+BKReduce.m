//
//  NSIndexSet+BKReduce.m
//  Wikipedia
//
//  Created by Brian Gerstle on 4/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSIndexSet+BKReduce.h"

@implementation NSIndexSet (BKReduce)

- (id)bk_reduce:(id)acc withBlock:(id (^)(id acc, NSUInteger idx))reducer {
    if (!reducer) {
        return acc;
    } else if (!acc) {
        return nil;
    }
    __block id result = acc;
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop) {
        result = reducer(acc, idx);
    }];
    return result;
}

@end
