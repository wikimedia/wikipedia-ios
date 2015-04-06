//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTAnswer.h"


@interface MKTThrowsException : NSObject <MKTAnswer>

- (instancetype)initWithException:(NSException *)exception;

@end
