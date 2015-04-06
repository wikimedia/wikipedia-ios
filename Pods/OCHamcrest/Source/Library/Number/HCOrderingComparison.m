//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCOrderingComparison.h"


@interface HCOrderingComparison ()
@property (readonly, nonatomic, strong) id expected;
@property (readonly, nonatomic, assign) NSComparisonResult minCompare;
@property (readonly, nonatomic, assign) NSComparisonResult maxCompare;
@property (readonly, nonatomic, copy) NSString *comparisonDescription;
@end

@implementation HCOrderingComparison

+ (instancetype)compare:(id)expectedValue
             minCompare:(NSComparisonResult)min
             maxCompare:(NSComparisonResult)max
  comparisonDescription:(NSString *)description
{
    return [[self alloc] initComparing:expectedValue
                            minCompare:min
                            maxCompare:max
                 comparisonDescription:description];
}

- (instancetype)initComparing:(id)expectedValue
                   minCompare:(NSComparisonResult)min
                   maxCompare:(NSComparisonResult)max
        comparisonDescription:(NSString *)description
{
    if (![expectedValue respondsToSelector:@selector(compare:)])
    {
        @throw [NSException exceptionWithName: @"UncomparableObject"
                                       reason: @"Object must respond to compare:"
                                     userInfo: nil];
    }

    self = [super init];
    if (self)
    {
        _expected = expectedValue;
        _minCompare = min;
        _maxCompare = max;
        _comparisonDescription = [description copy];
    }
    return self;
}

- (BOOL)matches:(id)item
{
    if (item == nil)
        return NO;

    NSComparisonResult compare;
    @try
    {
        compare = [self.expected compare:item];
    }
    @catch (NSException *e)
    {
        return NO;
    }
    return self.minCompare <= compare && compare <= self.maxCompare;
}

- (void)describeTo:(id<HCDescription>)description
{
    [[[[description appendText:@"a value "]
                    appendText:self.comparisonDescription]
                    appendText:@" "]
                    appendDescriptionOf:self.expected];
}

@end


id HC_greaterThan(id aValue)
{
    return [HCOrderingComparison compare:aValue
                              minCompare:NSOrderedAscending
                              maxCompare:NSOrderedAscending
                   comparisonDescription:@"greater than"];
}

id HC_greaterThanOrEqualTo(id aValue)
{
    return [HCOrderingComparison compare:aValue
                              minCompare:NSOrderedAscending
                              maxCompare:NSOrderedSame
                   comparisonDescription:@"greater than or equal to"];
}

id HC_lessThan(id aValue)
{
    return [HCOrderingComparison compare:aValue
                              minCompare:NSOrderedDescending
                              maxCompare:NSOrderedDescending
                   comparisonDescription:@"less than"];
}

id HC_lessThanOrEqualTo(id aValue)
{
    return [HCOrderingComparison compare:aValue
                              minCompare:NSOrderedSame
                              maxCompare:NSOrderedDescending
                   comparisonDescription:@"less than or equal to"];
}
