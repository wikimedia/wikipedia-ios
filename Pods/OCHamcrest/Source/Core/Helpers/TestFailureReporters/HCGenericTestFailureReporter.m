//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCGenericTestFailureReporter.h"

#import "HCTestFailure.h"


@implementation HCGenericTestFailureReporter

- (BOOL)willHandleFailure:(HCTestFailure *)failure
{
    return YES;
}

- (void)executeHandlingOfFailure:(HCTestFailure *)failure;
{
    NSException *exception = [self createExceptionForFailure:failure];
    [exception raise];
}

- (NSException *)createExceptionForFailure:(HCTestFailure *)failure
{
    NSString *failureReason = [NSString stringWithFormat:@"%@:%lu: matcher error: %@",
                                                         failure.fileName,
                                                         (unsigned long)failure.lineNumber,
                                                         failure.reason];
    return [NSException exceptionWithName:@"HCGenericTestFailure" reason:failureReason userInfo:nil];
}

@end
