//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCStringEndsWith.h"


@implementation HCStringEndsWith

+ (instancetype)stringEndsWith:(NSString *)aString
{
    return [[self alloc] initWithSubstring:aString];
}

- (BOOL)matches:(id)item
{
    if (![item respondsToSelector:@selector(hasSuffix:)])
        return NO;

    return [item hasSuffix:self.substring];
}

- (NSString *)relationship
{
    return @"ending with";
}

@end


id HC_endsWith(NSString *aString)
{
    return [HCStringEndsWith stringEndsWith:aString];
}
