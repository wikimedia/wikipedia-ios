//  Created by Monte Hurd on 8/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSArray (Predicate)

// Fast retrieval of first object in array matching predicate.
- (id)firstMatchForPredicate:(NSPredicate*)predicate;

@end
