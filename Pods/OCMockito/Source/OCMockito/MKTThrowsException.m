//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTThrowsException.h"


@interface MKTThrowsException ()
@property (readonly, nonatomic, strong) NSException *exception;
@end

@implementation MKTThrowsException

- (instancetype)initWithException:(NSException *)exception
{
    self = [super init];
    if (self)
        _exception = exception;
    return self;
}

- (id)answerInvocation:(NSInvocation *)invocation
{
    [self.exception raise];
    return nil;
}

@end
