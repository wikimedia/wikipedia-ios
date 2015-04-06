//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTAnswer.h"


@interface MKTExecutesBlock : NSObject <MKTAnswer>

- (instancetype)initWithBlock:(id (^)(NSInvocation *))block;

@end
