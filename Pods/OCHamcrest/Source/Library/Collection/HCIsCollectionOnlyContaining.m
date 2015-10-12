//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsCollectionOnlyContaining.h"

#import "HCAnyOf.h"
#import "HCCollect.h"


@implementation HCIsCollectionOnlyContaining

+ (instancetype)isCollectionOnlyContaining:(id <HCMatcher>)matcher
{
    return [[self alloc] initWithMatcher:matcher];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:@"a collection containing items matching "]
                  appendDescriptionOf:self.matcher];
}

@end


id HC_onlyContains(id itemMatch, ...)
{
    va_list args;
    va_start(args, itemMatch);
    NSArray *matchers = HCCollectMatchers(itemMatch, args);
    va_end(args);

    return [HCIsCollectionOnlyContaining isCollectionOnlyContaining:[HCAnyOf anyOf:matchers]];
}
