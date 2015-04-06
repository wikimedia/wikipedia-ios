//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsTrueFalse.h"


FOUNDATION_EXPORT id HC_isTrue(void)
{
    return [[HCIsTrue alloc] init];
}

@implementation HCIsTrue

- (BOOL)matches:(id)item
{
    if (![item isKindOfClass:[NSNumber class]])
        return NO;

    return [item boolValue];
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendText:@"true (non-zero)"];
}

@end

#pragma mark -

FOUNDATION_EXPORT id HC_isFalse(void)
{
    return [[HCIsFalse alloc] init];
}

@implementation HCIsFalse

- (BOOL)matches:(id)item
{
    if (![item isKindOfClass:[NSNumber class]])
        return NO;

    return ![item boolValue];
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendText:@"false (zero)"];
}

@end
