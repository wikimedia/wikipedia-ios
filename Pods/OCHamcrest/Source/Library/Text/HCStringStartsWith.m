//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCStringStartsWith.h"


@implementation HCStringStartsWith

+ (instancetype)stringStartsWith:(NSString *)aSubstring
{
    return [[self alloc] initWithSubstring:aSubstring];
}

- (BOOL)matches:(id)item
{
    if (![item respondsToSelector:@selector(hasPrefix:)])
        return NO;

    return [item hasPrefix:self.substring];
}

- (NSString *)relationship
{
    return @"starting with";
}

@end


id HC_startsWith(NSString *aString)
{
    return [HCStringStartsWith stringStartsWith:aString];
}
