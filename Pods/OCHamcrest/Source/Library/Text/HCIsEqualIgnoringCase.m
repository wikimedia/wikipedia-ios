//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsEqualIgnoringCase.h"

#import "HCRequireNonNilObject.h"


@interface HCIsEqualIgnoringCase ()
@property (readonly, nonatomic, copy) NSString *string;
@end

@implementation HCIsEqualIgnoringCase

+ (instancetype)isEqualIgnoringCase:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string
{
    HCRequireNonNilObject(string);

    self = [super init];
    if (self)
        _string = [string copy];
    return self;
}

- (BOOL)matches:(id)item
{
    if (![item isKindOfClass:[NSString class]])
        return NO;

    return [self.string caseInsensitiveCompare:item] == NSOrderedSame;
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendDescriptionOf:self.string]
                  appendText:@" ignoring case"];
}

@end


id HC_equalToIgnoringCase(NSString *aString)
{
    return [HCIsEqualIgnoringCase isEqualIgnoringCase:aString];
}
