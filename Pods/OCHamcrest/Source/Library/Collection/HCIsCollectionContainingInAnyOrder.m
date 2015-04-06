//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsCollectionContainingInAnyOrder.h"

#import "HCCollect.h"


@interface HCMatchingInAnyOrder : NSObject
@property (readonly, nonatomic, copy) NSMutableArray *matchers;
@property (readonly, nonatomic, strong) id <HCDescription, NSObject> mismatchDescription;
@end

@implementation HCMatchingInAnyOrder

- (instancetype)initWithMatchers:(NSArray *)itemMatchers
             mismatchDescription:(id<HCDescription, NSObject>)description
{
    self = [super init];
    if (self)
    {
        _matchers = [itemMatchers mutableCopy];
        _mismatchDescription = description;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    NSUInteger index = 0;
    for (id <HCMatcher> matcher in self.matchers)
    {
        if ([matcher matches:item])
        {
            [self.matchers removeObjectAtIndex:index];
            return YES;
        }
        ++index;
    }
    [[self.mismatchDescription appendText:@"not matched: "]
                               appendDescriptionOf:item];
    return NO;
}

- (BOOL)isFinishedWith:(NSArray *)collection
{
    if ([self.matchers count] == 0)
        return YES;

    [[[[self.mismatchDescription appendText:@"no item matches: "]
                                 appendList:self.matchers start:@"" separator:@", " end:@""]
                                 appendText:@" in "]
                                 appendList:collection start:@"[" separator:@", " end:@"]"];
    return NO;
}

@end


@interface HCIsCollectionContainingInAnyOrder ()
@property (readonly, nonatomic, copy) NSArray *matchers;
@end

@implementation HCIsCollectionContainingInAnyOrder

+ (instancetype)isCollectionContainingInAnyOrder:(NSArray *)itemMatchers
{
    return [[self alloc] initWithMatchers:itemMatchers];
}

- (instancetype)initWithMatchers:(NSArray *)itemMatchers
{
    self = [super init];
    if (self)
        _matchers = [itemMatchers copy];
    return self;
}

- (BOOL)matches:(id)collection describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    if (![collection conformsToProtocol:@protocol(NSFastEnumeration)])
    {
        [[mismatchDescription appendText:@"was non-collection "] appendDescriptionOf:collection];
        return NO;
    }

    HCMatchingInAnyOrder *matchSequence =
        [[HCMatchingInAnyOrder alloc] initWithMatchers:self.matchers
                                   mismatchDescription:mismatchDescription];
    for (id item in collection)
        if (![matchSequence matches:item])
            return NO;

    return [matchSequence isFinishedWith:collection];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[[description appendText:@"a collection over "]
                   appendList:self.matchers start:@"[" separator:@", " end:@"]"]
                   appendText:@" in any order"];
}

@end


id HC_containsInAnyOrder(id itemMatch, ...)
{
    va_list args;
    va_start(args, itemMatch);
    NSArray *matchers = HCCollectMatchers(itemMatch, args);
    va_end(args);

    return [HCIsCollectionContainingInAnyOrder isCollectionContainingInAnyOrder:matchers];
}
