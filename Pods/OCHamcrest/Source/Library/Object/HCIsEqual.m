//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsEqual.h"


@interface HCIsEqual ()

@property (readonly, nonatomic, strong) id object;
@end


@implementation HCIsEqual

+ (instancetype)isEqualTo:(id)object
{
    return [[self alloc] initEqualTo:object];
}

- (instancetype)initEqualTo:(id)object
{
    self = [super init];
    if (self)
        _object = object;
    return self;
}

- (BOOL)matches:(id)item
{
    if (item == nil)
        return self.object == nil;
    return [item isEqual:self.object];
}

- (void)describeTo:(id<HCDescription>)description
{
    if ([self.object conformsToProtocol:@protocol(HCMatcher)])
    {
        [[[description appendText:@"<"]
                       appendDescriptionOf:self.object]
                       appendText:@">"];
    }
    else
        [description appendDescriptionOf:self.object];
}

@end


id HC_equalTo(id object)
{
    return [HCIsEqual isEqualTo:object];
}
