//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTSelectorArgumentGetter.h"

@implementation MKTSelectorArgumentGetter

- (instancetype)initWithSuccessor:(MKTArgumentGetter *)successor
{
    self = [super initWithType:@encode(SEL) successor:successor];
    return self;
}

- (id)getArgumentAtIndex:(NSInteger)idx ofType:(char const *)type onInvocation:(NSInvocation *)invocation
{
    SEL arg = nil;
    [invocation getArgument:&arg atIndex:idx];
    return arg ? NSStringFromSelector(arg) : [NSNull null];
}

@end
