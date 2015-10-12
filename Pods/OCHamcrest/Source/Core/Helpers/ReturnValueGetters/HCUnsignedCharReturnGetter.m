//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCUnsignedCharReturnGetter.h"


@implementation HCUnsignedCharReturnGetter

- (instancetype)initWithSuccessor:(HCReturnValueGetter *)successor
{
    self = [super initWithType:@encode(unsigned char) successor:successor];
    return self;
}

- (id)returnValueFromInvocation:(NSInvocation *)invocation
{
    unsigned char value;
    [invocation getReturnValue:&value];
    return @(value);
}

@end
