//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsCollectionContainingInOrder.h"

#import "HCCollect.h"


@interface HCMatchSequence : NSObject
@property (readonly, nonatomic, copy) NSArray *matchers;
@property (readonly, nonatomic, strong) id <HCDescription, NSObject> mismatchDescription;
@property (nonatomic, assign) NSUInteger nextMatchIndex;
@end

@implementation HCMatchSequence

- (instancetype)initWithMatchers:(NSArray *)itemMatchers
             mismatchDescription:(id<HCDescription, NSObject>)description
{
    self = [super init];
    if (self)
    {
        _matchers = [itemMatchers copy];
        _mismatchDescription = description;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    return [self isNotSurplus:item] && [self isMatched:item];
}

- (BOOL)isFinished
{
    if (self.nextMatchIndex < [self.matchers count])
    {
        [[self.mismatchDescription appendText:@"no item was "]
                              appendDescriptionOf:self.matchers[self.nextMatchIndex]];
        return NO;
    }
    return YES;
}

- (BOOL)isMatched:(id)item
{
    id <HCMatcher> matcher = self.matchers[self.nextMatchIndex];
    if (![matcher matches:item])
    {
        [self describeMismatchOfMatcher:matcher item:item];
        return NO;
    }
    ++self.nextMatchIndex;
    return YES;
}

- (BOOL)isNotSurplus:(id)item
{
    if ([self.matchers count] <= self.nextMatchIndex)
    {
        [[self.mismatchDescription appendText:@"not matched: "] appendDescriptionOf:item];
        return NO;
    }
    return YES;
}

- (void)describeMismatchOfMatcher:(id <HCMatcher>)matcher item:(id)item
{
    [self.mismatchDescription appendText:[NSString stringWithFormat:@"item %zi: ", self.nextMatchIndex]];
    [matcher describeMismatchOf:item to:self.mismatchDescription];
}

@end


@interface HCIsCollectionContainingInOrder ()
@property (readonly, nonatomic, copy) NSArray *matchers;
@end

@implementation HCIsCollectionContainingInOrder

+ (instancetype)isCollectionContainingInOrder:(NSArray *)itemMatchers
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

- (BOOL)matches:(id)collection describingMismatchTo:(id<HCDescription, NSObject>)mismatchDescription
{
    if (![collection conformsToProtocol:@protocol(NSFastEnumeration)])
    {
        [[mismatchDescription appendText:@"was non-collection "] appendDescriptionOf:collection];
        return NO;
    }

    HCMatchSequence *matchSequence =
        [[HCMatchSequence alloc] initWithMatchers:self.matchers
                              mismatchDescription:mismatchDescription];
    for (id item in collection)
        if (![matchSequence matches:item])
            return NO;

    return [matchSequence isFinished];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:@"a collection containing "]
                  appendList:self.matchers start:@"[" separator:@", " end:@"]"];
}

@end


id HC_contains(id itemMatch, ...)
{
    va_list args;
    va_start(args, itemMatch);
    NSArray *matchers = HCCollectMatchers(itemMatch, args);
    va_end(args);

    return [HCIsCollectionContainingInOrder isCollectionContainingInOrder:matchers];
}
