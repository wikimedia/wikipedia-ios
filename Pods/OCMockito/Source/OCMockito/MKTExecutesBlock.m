//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTExecutesBlock.h"


@interface MKTExecutesBlock ()
@property (readonly, nonatomic, copy) id (^block)(NSInvocation *);
@end

@implementation MKTExecutesBlock

- (instancetype)initWithBlock:(id (^)(NSInvocation *))block
{
    self = [super init];
    if (self)
        _block = [block copy];
    return self;
}

- (id)answerInvocation:(NSInvocation *)invocation
{
    return self.block(invocation);
}

@end
