//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTVerificationData.h"

#import "MKTInvocationContainer.h"
#import "MKTInvocationMatcher.h"


@implementation MKTVerificationData

- (NSUInteger)numberOfMatchingInvocations
{
    NSUInteger count = 0;
    for (NSInvocation *invocation in self.invocations.registeredInvocations)
    {
        if ([self.wanted matches:invocation])
            ++count;
    }
    return count;
}

- (void)captureArguments
{
    [self.wanted captureArgumentsFromInvocations:self.invocations.registeredInvocations];
}

@end
