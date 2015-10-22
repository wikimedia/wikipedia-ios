//
//  WMFAsyncBlockOperation.m
//  Wikipedia
//
//  Created by Corey Floyd on 10/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFAsyncBlockOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAsyncBlockOperation ()

@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, strong) WMFAsyncBlock block;

@end

@implementation WMFAsyncBlockOperation

- (instancetype)initWithBlock:(WMFAsyncBlock)block {
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    self.block(self);
}

- (void)finish {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isExecuting = NO;
    self.isFinished  = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end


@implementation NSOperationQueue (AsyncBlockOperation)

- (void)wmf_addOperationWithAsyncBlock:(WMFAsyncBlock)block {
    WMFAsyncBlockOperation* operation = [[WMFAsyncBlockOperation alloc] initWithBlock:block];
    [self addOperation:operation];
}

@end

NS_ASSUME_NONNULL_END