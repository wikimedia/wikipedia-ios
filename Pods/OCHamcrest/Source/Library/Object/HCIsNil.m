//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsNil.h"

#import "HCIsNot.h"


@implementation HCIsNil

+ (instancetype)isNil
{
    return [[self alloc] init];
}

- (BOOL)matches:(id)item
{
    return item == nil;
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendText:@"nil"];
}

@end


id HC_nilValue()
{
    return [HCIsNil isNil];
}

id HC_notNilValue()
{
    return HC_isNot([HCIsNil isNil]);
}
