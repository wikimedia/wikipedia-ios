//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsInstanceOf.h"


@implementation HCIsInstanceOf

+ (instancetype)isInstanceOf:(Class)aClass
{
    return [[self alloc] initWithClass:aClass];
}

- (BOOL)matches:(id)item
{
    return [item isKindOfClass:self.theClass];
}

- (NSString *)expectation
{
    return @"an instance of ";
}

@end


id HC_instanceOf(Class aClass)
{
    return [HCIsInstanceOf isInstanceOf:aClass];
}
