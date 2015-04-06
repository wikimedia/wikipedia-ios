//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCGenericTestFailureHandler.h"

#import "HCTestFailure.h"


@implementation HCGenericTestFailureHandler

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
    return [NSException exceptionWithName:@"Hamcrest Error" reason:failureReason userInfo:nil];
}

@end
