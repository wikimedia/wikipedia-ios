//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTReturnValueSetter.h"


@interface MKTReturnValueSetter (SubclassResponsibility)
- (void)setReturnValue:(id)returnValue onInvocation:(NSInvocation *)invocation;
@end

@interface MKTReturnValueSetter ()
@property (readonly, nonatomic, assign) char const *handlerType;
@property (readonly, nonatomic, strong) MKTReturnValueSetter *successor;
@end


@implementation MKTReturnValueSetter

- (instancetype)initWithType:(char const *)handlerType successor:(MKTReturnValueSetter *)successor
{
    self = [super init];
    if (self)
    {
        _handlerType = handlerType;
        _successor = successor;
    }
    return self;
}

- (BOOL)handlesReturnType:(char const *)returnType
{
    return returnType[0] == self.handlerType[0];
}

- (void)setReturnValue:(id)returnValue ofType:(char const *)type onInvocation:(NSInvocation *)invocation
{
    if ([self handlesReturnType:type])
        [self setReturnValue:returnValue onInvocation:invocation];
    else
        [self.successor setReturnValue:returnValue ofType:type onInvocation:invocation];
}

@end
