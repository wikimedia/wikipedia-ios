//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsCloseTo.h"


@interface HCIsCloseTo ()

@property (nonatomic, assign, readonly) double value;
@property (nonatomic, assign, readonly) double delta;
@end


@implementation HCIsCloseTo

+ (id)isCloseTo:(double)value within:(double)delta
{
    return [[self alloc] initWithValue:value delta:delta];
}

- (id)initWithValue:(double)value delta:(double)delta
{
    self = [super init];
    if (self)
    {
        _value = value;
        _delta = delta;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    if ([self itemIsNotNumber:item])
        return NO;

    return fabs([item doubleValue] - self.value) <= self.delta;
}

- (BOOL)itemIsNotNumber:(id)item
{
    return ![item isKindOfClass:[NSNumber class]];
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    if ([self itemIsNotNumber:item])
        [super describeMismatchOf:item to:mismatchDescription];
    else
    {
        double actualDelta = fabs([item doubleValue] - self.value);
        [[[mismatchDescription appendDescriptionOf:item]
                               appendText:@" differed by "]
                               appendDescriptionOf:@(actualDelta)];
    }
}

- (void)describeTo:(id<HCDescription>)description
{
    [[[[description appendText:@"a numeric value within "]
                    appendDescriptionOf:@(self.delta)]
                    appendText:@" of "]
                    appendDescriptionOf:@(self.value)];
}

@end


id HC_closeTo(double value, double delta)
{
    return [HCIsCloseTo isCloseTo:value within:delta];
}
