//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTMockitoCore.h"

#import "MKTMockingProgress.h"
#import "MKTVerificationMode.h"


@interface MKTMockitoCore ()

@property (readonly, nonatomic, strong) MKTMockingProgress *mockingProgress;
@end


@implementation MKTMockitoCore


+ (instancetype)sharedCore
{
    static id sharedCore = nil;
    if (!sharedCore)
        sharedCore = [[self alloc] init];
    return sharedCore;
}

- (instancetype)init
{
    self = [super init];
    if (self)
        _mockingProgress = [MKTMockingProgress sharedProgress];
    return self;
}

- (MKTOngoingStubbing *)stubAtLocation:(MKTTestLocation)location
{
    [self.mockingProgress stubbingStartedAtLocation:location];
    return [self stub];
}

- (MKTOngoingStubbing *)stub
{
    return [self.mockingProgress pullOngoingStubbing];
}

- (id)verifyMock:(MKTObjectMock *)mock
        withMode:(id <MKTVerificationMode>)mode
      atLocation:(MKTTestLocation)location
{
    [self.mockingProgress verificationStarted:mode atLocation:location];
    return mock;
}

@end
