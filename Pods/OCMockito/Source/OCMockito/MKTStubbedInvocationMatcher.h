//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTInvocationMatcher.h"
#import "MKTAnswer.h"


@interface MKTStubbedInvocationMatcher : MKTInvocationMatcher <MKTAnswer>

- (void)addAnswer:(id <MKTAnswer>)answer;

@end
