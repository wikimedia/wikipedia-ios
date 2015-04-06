//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsAnything.h"


@implementation HCIsAnything

+ (instancetype)isAnything
{
    return [[self alloc] init];
}

+ (instancetype)isAnythingWithDescription:(NSString *)aDescription
{
    return [[self alloc] initWithDescription:aDescription];
}

- (instancetype)init
{
    self = [self initWithDescription:@"ANYTHING"];
    return self;
}

- (instancetype)initWithDescription:(NSString *)aDescription
{
    self = [super init];
    if (self)
        description = [aDescription copy];
    return self;
}

- (BOOL)matches:(id)item
{
    return YES;
}

- (void)describeTo:(id<HCDescription>)aDescription
{
    [aDescription appendText:description];
}

@end


id HC_anything()
{
    return [HCIsAnything isAnything];
}

id HC_anythingWithDescription(NSString *description)
{
    return [HCIsAnything isAnythingWithDescription:description];
}
