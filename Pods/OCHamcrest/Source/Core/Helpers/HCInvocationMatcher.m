//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCInvocationMatcher.h"


@implementation HCInvocationMatcher

- (instancetype)initWithInvocation:(NSInvocation *)anInvocation matching:(id <HCMatcher>)aMatcher
{
    self = [super init];
    if (self)
    {
        _invocation = anInvocation;
        _subMatcher = aMatcher;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    if ([self invocationNotSupportedForItem:item])
        return NO;

    return [_subMatcher matches:[self invokeOn:item]];
}

- (BOOL)invocationNotSupportedForItem:(id)item
{
    return ![item respondsToSelector:[_invocation selector]];
}

- (id)invokeOn:(id)item
{
    __unsafe_unretained id result = nil;
    [_invocation invokeWithTarget:item];
    [_invocation getReturnValue:&result];
    return result;
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    if ([self invocationNotSupportedForItem:item])
        [super describeMismatchOf:item to:mismatchDescription];
    else
    {
        [self describeLongMismatchDescriptionOf:item to:mismatchDescription];
        [_subMatcher describeMismatchOf:[self invokeOn:item] to:mismatchDescription];
    }
}

- (void)describeLongMismatchDescriptionOf:(id)item to:(id <HCDescription>)mismatchDescription
{
    if (!self.shortMismatchDescription)
    {
        [[[[mismatchDescription appendDescriptionOf:item]
                                appendText:@" "]
                                appendText:[self stringFromSelector]]
                                appendText:@" "];
    }
}

- (void)describeTo:(id<HCDescription>)description
{
    [[[[description appendText:@"an object with "]
            appendText:[self stringFromSelector]]
            appendText:@" "]
            appendDescriptionOf:_subMatcher];
}

- (NSString *)stringFromSelector
{
    return NSStringFromSelector([_invocation selector]);
}

@end
