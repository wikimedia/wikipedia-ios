//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTReturnsValue.h"


@interface MKTReturnsValue ()
@property (readonly, nonatomic, strong) id value;
@end

@implementation MKTReturnsValue

- (instancetype)initWithValue:(id)value
{
    self = [super init];
    if (self)
        _value = value;
    return self;
}

- (id)answerInvocation:(NSInvocation *)invocation
{
    return self.value;
}

@end
