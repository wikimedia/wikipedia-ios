//
//  NSArray+WMFExtensions.m
//  Wikipedia
//
//  Created by Corey Floyd on 2/18/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSArray+WMFExtensions.h"

@implementation NSArray (WMFExtensions)

- (instancetype)wmf_arrayByTrimmingToLength:(NSUInteger)length {
    if ([self count] == 0) {
        return self;
    }

    if ([self count] < length) {
        return self;
    }

    return [self subarrayWithRange:NSMakeRange(0, length)];
}

- (instancetype)wmf_reverseArray {
    return [[self reverseObjectEnumerator] allObjects];
}

@end
