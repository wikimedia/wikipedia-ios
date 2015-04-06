//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTObjectMock.h"

#import "MKTDynamicProperties.h"


@interface MKTObjectMock ()
@property (readonly, nonatomic, strong) Class mockedClass;
@property (nonatomic, strong) MKTDynamicProperties *dynamicProperties;
@end

@implementation MKTObjectMock

+ (instancetype)mockForClass:(Class)aClass
{
    return [[self alloc] initWithClass:aClass];
}

- (instancetype)initWithClass:(Class)aClass
{
    self = [super init];
    if (self)
    {
        _mockedClass = aClass;
        _dynamicProperties = [[MKTDynamicProperties alloc] initWithClass:aClass];
    }
    return self;
}

- (NSString *)description
{
    return [@"mock object of " stringByAppendingString:NSStringFromClass(self.mockedClass)];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *dynamicPropertySignature = [self.dynamicProperties methodSignatureForSelector:aSelector];
    if (dynamicPropertySignature)
        return dynamicPropertySignature;
    return [self.mockedClass instanceMethodSignatureForSelector:aSelector];
}


#pragma mark NSObject protocol

- (BOOL)isKindOfClass:(Class)aClass
{
    return [self.mockedClass isSubclassOfClass:aClass];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.dynamicProperties methodSignatureForSelector:aSelector] ||
           [self.mockedClass instancesRespondToSelector:aSelector];
}

@end
