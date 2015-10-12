//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsSame.h"


@interface HCIsSame ()
@property (nonatomic, strong, readonly) id object;
@end

@implementation HCIsSame

+ (instancetype)isSameAs:(id)object
{
    return [[self alloc] initSameAs:object];
}

- (instancetype)initSameAs:(id)object
{
    self = [super init];
    if (self)
        _object = object;
    return self;
}

- (BOOL)matches:(id)item
{
    return item == self.object;
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    [mismatchDescription appendText:@"was "];
    if (item)
        [mismatchDescription appendText:[NSString stringWithFormat:@"%p ", (__bridge void *)item]];
    [mismatchDescription appendDescriptionOf:item];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:[NSString stringWithFormat:@"same instance as %p ", (__bridge void *)self.object]]
                  appendDescriptionOf:self.object];
}

@end


id HC_sameInstance(id object)
{
    return [HCIsSame isSameAs:object];
}
