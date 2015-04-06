//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCDiagnosingMatcher.h"


@implementation HCDiagnosingMatcher

- (BOOL)matches:(id)item
{
    return [self matches:item describingMismatchTo:nil];
}

- (BOOL)matches:(id)item describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    HC_ABSTRACT_METHOD;
    return NO;
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    [self matches:item describingMismatchTo:mismatchDescription];
}

@end
