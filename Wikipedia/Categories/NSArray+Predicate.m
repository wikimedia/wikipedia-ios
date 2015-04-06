//  Created by Monte Hurd on 8/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSArray+Predicate.h"

@implementation NSArray (Predicate)

- (id)firstMatchForPredicate:(NSPredicate*)predicate {
    NSInteger i = [self indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL* stop) {
        if ([predicate evaluateWithObject:obj]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    return i == NSNotFound ? nil : [self objectAtIndex:i];
}

@end
