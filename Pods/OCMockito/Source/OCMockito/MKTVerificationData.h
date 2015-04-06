//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>

#import "MKTTestLocation.h"

@class MKTInvocationContainer;
@class MKTInvocationMatcher;


@interface MKTVerificationData : NSObject

@property (nonatomic, strong) MKTInvocationContainer *invocations;
@property (nonatomic, strong) MKTInvocationMatcher *wanted;
@property (nonatomic, assign) MKTTestLocation testLocation;

- (NSUInteger)numberOfMatchingInvocations;
- (void)captureArguments;

@end
