//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsNot.h"

#import "HCWrapInMatcher.h"


@interface HCIsNot ()
@property (readonly, nonatomic, strong) id <HCMatcher> matcher;
@end

@implementation HCIsNot

+ (instancetype)isNot:(id <HCMatcher>)matcher
{
    return [[self alloc] initNot:matcher];
}

- (instancetype)initNot:(id <HCMatcher>)matcher
{
    self = [super init];
    if (self)
        _matcher = matcher;
    return self;
}

- (BOOL)matches:(id)item
{
    return ![self.matcher matches:item];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:@"not "] appendDescriptionOf:self.matcher];
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    [self.matcher describeMismatchOf:item to:mismatchDescription];
}
@end


id HC_isNot(id aMatcher)
{
    return [HCIsNot isNot:HCWrapInMatcher(aMatcher)];
}
