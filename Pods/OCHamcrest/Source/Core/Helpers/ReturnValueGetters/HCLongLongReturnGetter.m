//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCLongLongReturnGetter.h"


@implementation HCLongLongReturnGetter

- (instancetype)initWithSuccessor:(HCReturnValueGetter *)successor
{
    self = [super initWithType:@encode(long long) successor:successor];
    return self;
}

- (id)returnValueFromInvocation:(NSInvocation *)invocation
{
    long long value;
    [invocation getReturnValue:&value];
    return @(value);
}

@end
