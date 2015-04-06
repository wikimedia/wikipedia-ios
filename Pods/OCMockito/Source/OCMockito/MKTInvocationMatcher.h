//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>

@protocol HCMatcher;


@interface MKTInvocationMatcher : NSObject

@property (nonatomic, strong) NSInvocation *expected;
@property (nonatomic, assign) NSUInteger numberOfArguments;
@property (nonatomic, strong) NSMutableArray *argumentMatchers;

- (instancetype)init;
- (void)setMatcher:(id <HCMatcher>)matcher atIndex:(NSUInteger)index;
- (NSUInteger)argumentMatchersCount;
- (void)setExpectedInvocation:(NSInvocation *)expectedInvocation;
- (BOOL)matches:(NSInvocation *)actual;
- (void)captureArgumentsFromInvocations:(NSArray *)invocations;

@end
