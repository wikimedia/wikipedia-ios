//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTInvocationContainer.h"

#import "MKTStubbedInvocationMatcher.h"
#import "NSInvocation+OCMockito.h"


@interface MKTInvocationContainer ()
@property (nonatomic, strong) MKTStubbedInvocationMatcher *invocationForStubbing;
@property (readonly, nonatomic, strong) NSMutableArray *stubbed;
@end

@implementation MKTInvocationContainer


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _registeredInvocations = [[NSMutableArray alloc] init];
        _stubbed = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)setInvocationForPotentialStubbing:(NSInvocation *)invocation
{
    [invocation mkt_retainArgumentsWithWeakTarget];
    [_registeredInvocations addObject:invocation];

    MKTStubbedInvocationMatcher *s = [[MKTStubbedInvocationMatcher alloc] init];
    [s setExpectedInvocation:invocation];
    self.invocationForStubbing = s;
}

- (void)setMatcher:(id <HCMatcher>)matcher atIndex:(NSUInteger)argumentIndex
{
    [self.invocationForStubbing setMatcher:matcher atIndex:argumentIndex];
}

- (void)addAnswer:(id <MKTAnswer>)answer
{
    [_registeredInvocations removeLastObject];

    [self.invocationForStubbing addAnswer:answer];
    [self.stubbed insertObject:self.invocationForStubbing atIndex:0];
}

- (MKTStubbedInvocationMatcher *)findAnswerFor:(NSInvocation *)invocation
{
    for (MKTStubbedInvocationMatcher *s in self.stubbed)
        if ([s matches:invocation])
            return s;
    return nil;
}

@end
