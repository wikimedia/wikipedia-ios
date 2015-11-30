//
//  NSIndexSet+BKReduce.h
//  Wikipedia
//
//  Created by Brian Gerstle on 4/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (BKReduce)

- (id)bk_reduce:(id)acc withBlock:(id (^)(id acc, NSUInteger idx))reducer;

@end
