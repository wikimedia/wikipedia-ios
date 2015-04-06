//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTBlockArgumentGetter.h"

typedef void (^MKTBlockType)(void);

@implementation MKTBlockArgumentGetter

- (instancetype)initWithSuccessor:(MKTArgumentGetter *)successor
{
    self = [super initWithType:@encode(MKTBlockType) successor:successor];
    return self;
}

- (id)getArgumentAtIndex:(NSInteger)idx ofType:(char const *)type onInvocation:(NSInvocation *)invocation
{
    __unsafe_unretained id arg = nil;
    [invocation getArgument:&arg atIndex:idx];
    return arg ? [arg copy] : [NSNull null];
}

@end
