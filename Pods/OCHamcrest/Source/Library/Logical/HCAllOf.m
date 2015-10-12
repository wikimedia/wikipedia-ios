//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCAllOf.h"

#import "HCCollect.h"


@interface HCAllOf ()
@property (nonatomic, copy, readonly) NSArray *matchers;
@end

@implementation HCAllOf

+ (instancetype)allOf:(NSArray *)matchers
{
    return [[self alloc] initWithMatchers:matchers];
}

- (instancetype)initWithMatchers:(NSArray *)matchers
{
    self = [super init];
    if (self)
        _matchers = [matchers copy];
    return self;
}

- (BOOL)matches:(id)item describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    for (id <HCMatcher> oneMatcher in self.matchers)
    {
        if (![oneMatcher matches:item])
        {
            [[mismatchDescription appendDescriptionOf:oneMatcher] appendText:@" "];
            [oneMatcher describeMismatchOf:item to:mismatchDescription];
            return NO;
        }
    }
    return YES;
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendList:self.matchers start:@"(" separator:@" and " end:@")"];
}

@end


id HC_allOf(id match, ...)
{
    va_list args;
    va_start(args, match);
    NSArray *matcherList = HCCollectMatchers(match, args);
    va_end(args);

    return [HCAllOf allOf:matcherList];
}
