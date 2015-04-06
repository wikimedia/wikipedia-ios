//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTInvocationMatcher.h"

#import "MKTCapturingMatcher.h"
#import "NSInvocation+OCMockito.h"
#import <OCHamcrest/HCIsNil.h>
#import <OCHamcrest/HCWrapInMatcher.h>


@interface MKTUnspecifiedArgumentPlaceholder : NSObject
@end

@implementation MKTUnspecifiedArgumentPlaceholder

+ (instancetype)sharedPlaceholder
{
    static MKTUnspecifiedArgumentPlaceholder *instance = nil;
    if (!instance)
        instance = [[[self class] alloc] init];
    return instance;
}

@end


@implementation MKTInvocationMatcher

- (instancetype)init
{
    self = [super init];
    if (self)
        _argumentMatchers = [[NSMutableArray alloc] init];
    return self;
}

- (void)setMatcher:(id <HCMatcher>)matcher atIndex:(NSUInteger)index
{
    if (index < [self.argumentMatchers count])
        self.argumentMatchers[index] = matcher;
    else
    {
        [self trueUpArgumentMatchersToCount:index];
        [self.argumentMatchers addObject:matcher];
    }
}

- (NSUInteger)argumentMatchersCount
{
    return [self.argumentMatchers count];
}

- (void)trueUpArgumentMatchersToCount:(NSUInteger)desiredCount
{
    NSUInteger count = [self.argumentMatchers count];
    while (count < desiredCount)
    {
        [self.argumentMatchers addObject:[self placeholderForUnspecifiedMatcher]];
        ++count;
    }
}

- (void)setExpectedInvocation:(NSInvocation *)expectedInvocation
{
    [expectedInvocation mkt_retainArgumentsWithWeakTarget];
    self.expected = expectedInvocation;

    self.numberOfArguments = [[self.expected methodSignature] numberOfArguments] - 2;
    [self trueUpArgumentMatchersToCount:self.numberOfArguments];
    [self replacePlaceholdersWithEqualityMatchersForArguments:[self.expected mkt_arguments]];
}

- (void)replacePlaceholdersWithEqualityMatchersForArguments:(NSArray *)expectedArgs
{
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
    {
        if (self.argumentMatchers[index] == [self placeholderForUnspecifiedMatcher])
            self.argumentMatchers[index] = [self matcherForArgument:expectedArgs[index]];
    }
}

- (id)placeholderForUnspecifiedMatcher
{
    return [MKTUnspecifiedArgumentPlaceholder sharedPlaceholder];
}

- (id <HCMatcher>)matcherForArgument:(id)arg
{
    if (arg == [NSNull null])
        return HC_nilValue();

    return HCWrapInMatcher(arg);
}

- (BOOL)matches:(NSInvocation *)actual
{
    if ([self.expected selector] != [actual selector])
        return NO;

    NSArray *actualArgs = [actual mkt_arguments];
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
    {
        if ([self argument:actualArgs[index] doesNotMatch:self.argumentMatchers[index]])
            return NO;
    }
    return YES;
}

- (BOOL)argument:(id)arg doesNotMatch:(id <HCMatcher>)matcher
{
    if (arg == [NSNull null])
        arg = nil;
    return ![matcher matches:arg];
}

- (void)captureArgumentsFromInvocations:(NSArray *)invocations
{
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
    {
        id <HCMatcher> matcher = self.argumentMatchers[index];
        if ([matcher respondsToSelector:@selector(captureArgument:)])
            [self captureArgumentsAtIndex:index acrossInvocations:invocations intoMatcher:matcher];
    }
}

- (void)captureArgumentsAtIndex:(NSUInteger)index
              acrossInvocations:(NSArray *)invocations
                    intoMatcher:(id <HCMatcher>)capturingMatcher
{
    for (NSInvocation *inv in invocations)
    {
        if ([self.expected selector] == [inv selector])
        {
            NSArray *args = [inv mkt_arguments];
            [capturingMatcher performSelector:@selector(captureArgument:) withObject:args[index]];
        }
    }
}

@end
