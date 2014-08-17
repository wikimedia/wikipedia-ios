//  Created by Monte Hurd on 8/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSArray+Predicate.h"

@implementation NSArray (Predicate)

-(id)firstMatchForPredicate:(NSPredicate *)predicate {
    __block id matchingObject = nil;
    [self enumerateObjectsUsingBlock:
        ^(id obj, NSUInteger idx, BOOL *stop) {
            BOOL matchFound = [predicate evaluateWithObject:obj];
            if (matchFound) matchingObject = obj;
            *stop = matchFound;
        }
    ];
    return matchingObject;
}

@end
