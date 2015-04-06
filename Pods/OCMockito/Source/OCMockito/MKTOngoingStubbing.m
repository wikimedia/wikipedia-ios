//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <OCHamcrest/OCHamcrest.h>
#import "MKTOngoingStubbing.h"

#import "MKTInvocationContainer.h"
#import "MKTReturnsValue.h"
#import "MKTThrowsException.h"
#import "MKTExecutesBlock.h"


@interface MKTOngoingStubbing ()
@property (readonly, nonatomic, strong) MKTInvocationContainer *invocationContainer;
@end

@implementation MKTOngoingStubbing

- (instancetype)initWithInvocationContainer:(MKTInvocationContainer *)invocationContainer
{
    self = [super init];
    if (self)
        _invocationContainer = invocationContainer;
    return self;
}

- (MKTOngoingStubbing *)willReturn:(id)object
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:object];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnStruct:(const void *)value objCType:(const char *)type
{
    NSValue *answer = [NSValue valueWithBytes:value objCType:type];
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:answer];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnBool:(BOOL)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnChar:(char)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnInt:(int)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnShort:(short)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnLong:(long)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnLongLong:(long long)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnInteger:(NSInteger)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedChar:(unsigned char)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedInt:(unsigned int)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedShort:(unsigned short)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedLong:(unsigned long)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedLongLong:(unsigned long long)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnUnsignedInteger:(NSUInteger)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnFloat:(float)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willReturnDouble:(double)value
{
    MKTReturnsValue *returnsValue = [[MKTReturnsValue alloc] initWithValue:@(value)];
    [self.invocationContainer addAnswer:returnsValue];
    return self;
}

- (MKTOngoingStubbing *)willThrow:(NSException *)exception
{
    MKTThrowsException *throwsException = [[MKTThrowsException alloc] initWithException:exception];
    [self.invocationContainer addAnswer:throwsException];
    return self;
}

- (MKTOngoingStubbing *)willDo:(id (^)(NSInvocation *))block
{
    MKTExecutesBlock *executesBlock = [[MKTExecutesBlock alloc] initWithBlock:block];
    [self.invocationContainer addAnswer:executesBlock];
    return self;
}


#pragma mark MKTPrimitiveArgumentMatching

- (id)withMatcher:(id <HCMatcher>)matcher forArgument:(NSUInteger)index
{
    [self.invocationContainer setMatcher:matcher atIndex:index];
    return self;
}

- (id)withMatcher:(id <HCMatcher>)matcher
{
    return [self withMatcher:matcher forArgument:0];
}

@end
