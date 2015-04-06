//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsTypeOf.h"


@implementation HCIsTypeOf

+ (instancetype)isTypeOf:(Class)type
{
    return [[self alloc] initWithType:type];
}

- (BOOL)matches:(id)item
{
    return [item isMemberOfClass:self.theClass];
}

- (NSString *)expectation
{
    return @"an exact instance of ";
}

@end


id HC_isA(Class aClass)
{
    return [HCIsTypeOf isTypeOf:aClass];
}
