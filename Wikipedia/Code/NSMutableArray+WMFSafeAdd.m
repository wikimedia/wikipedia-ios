//
//  NSMutableArray+WMFMaybeAdd.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSMutableArray+WMFSafeAdd.h"

@implementation NSMutableArray (WMFMaybeAdd)

- (BOOL)wmf_safeAddObject:(nullable id)object {
    if (object) {
        [self addObject:object];
        return YES;
    }
    return NO;
}

@end
