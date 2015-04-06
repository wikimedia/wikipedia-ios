//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsIn.h"


@interface HCIsIn ()
@property (readonly, nonatomic, strong) id collection;
@end

@implementation HCIsIn

+ (instancetype)isInCollection:(id)collection
{
    return [[self alloc] initWithCollection:collection];
}

- (instancetype)initWithCollection:(id)collection
{
    if (![collection respondsToSelector:@selector(containsObject:)])
    {
        @throw [NSException exceptionWithName:@"NotAContainer"
                                       reason:@"Object must respond to -containsObject:"
                                     userInfo:nil];
    }

    self = [super init];
    if (self)
        _collection = collection;
    return self;
}

- (BOOL)matches:(id)item
{
    return [self.collection containsObject:item];
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:@"one of "]
                  appendList:self.collection start:@"{" separator:@", " end:@"}"];
}

@end


id HC_isIn(id aCollection)
{
    return [HCIsIn isInCollection:aCollection];
}
