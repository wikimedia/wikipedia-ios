//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCAssertThat.h"

#import "HCStringDescription.h"
#import "HCMatcher.h"
#import "HCTestFailure.h"
#import "HCTestFailureReporter.h"
#import "HCTestFailureReporterChain.h"
#import <libkern/OSAtomic.h>


static NSString *describeMismatch(id matcher, id actual)
{
    HCStringDescription *description = [HCStringDescription stringDescription];
    [[[description appendText:@"Expected "]
            appendDescriptionOf:matcher]
            appendText:@", but "];
    [matcher describeMismatchOf:actual to:description];
    return [description description];
}

static void reportMismatch(id testCase, id actual, id <HCMatcher> matcher,
                           char const *fileName, int lineNumber)
{
    HCTestFailure *failure = [[HCTestFailure alloc] initWithTestCase:testCase
                                                            fileName:[NSString stringWithUTF8String:fileName]
                                                          lineNumber:(NSUInteger)lineNumber
                                                              reason:describeMismatch(matcher, actual)];
    HCTestFailureReporter *chain = [HCTestFailureReporterChain reporterChain];
    [chain handleFailure:failure];
}

void HC_assertThatWithLocation(id testCase, id actual, id <HCMatcher> matcher,
                               const char *fileName, int lineNumber)
{
    if (![matcher matches:actual])
        reportMismatch(testCase, actual, matcher, fileName, lineNumber);
}

void HC_assertThatAfterWithLocation(id testCase, NSTimeInterval maxTime,
                                    HCAssertThatAfterActualBlock actualBlock, id<HCMatcher> matcher,
                                    const char *fileName, int lineNumber)
{
    HC_assertWithTimeoutAndLocation(testCase, maxTime, actualBlock, matcher, fileName, lineNumber);
}

void HC_assertWithTimeoutAndLocation(id testCase, NSTimeInterval timeout, HCFutureValue actualBlock, id <HCMatcher> matcher, const char *fileName, int lineNumber)
{
    BOOL match;
    id actual;
    NSDate *expiryDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (1)
    {
        actual = actualBlock();
        match = [matcher matches:actual];
        if (match || ([[NSDate date] compare:expiryDate] == NSOrderedDescending))
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        OSMemoryBarrier();
    }

    if (!match)
        reportMismatch(testCase, actual, matcher, fileName, lineNumber);
}
