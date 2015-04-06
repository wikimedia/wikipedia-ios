//
//  NSArray+BKIndex.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSArray+BKIndex.h"
#import <BlocksKit/BlocksKit.h>

@implementation NSArray (BKIndex)

- (NSDictionary*)bk_index:(id<NSCopying>(^)(id))index {
    return [self bk_reduce:[NSMutableDictionary dictionaryWithCapacity:self.count]
                 withBlock:^NSMutableDictionary*(NSMutableDictionary* acc, id obj) {
        acc[index(obj)] = obj;
        return acc;
    }];
}

- (NSDictionary*)bk_indexWithKeypath:(NSString*)keypath {
    return [self bk_index:^id < NSCopying > (id obj) {
        return [obj valueForKeyPath:keypath];
    }];
}

@end
