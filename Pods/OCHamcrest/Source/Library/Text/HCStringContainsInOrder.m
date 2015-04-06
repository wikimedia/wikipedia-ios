//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCStringContainsInOrder.h"

#import "HCCollect.h"


@implementation HCStringContainsInOrder

+ (instancetype)containsInOrder:(NSArray *)substringList
{
    return [[self alloc] initWithSubstrings:substringList];
}

- (instancetype)initWithSubstrings:(NSArray *)substringList
{
    self = [super init];
    if (self)
    {
        for (id substring in substringList)
        {
            if (![substring isKindOfClass:[NSString class]])
            {
                @throw [NSException exceptionWithName:@"NotAString"
                                               reason:@"Arguments must be strings"
                                             userInfo:nil];
            }
        }

        substrings = substringList;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    if (![item isKindOfClass:[NSString class]])
        return NO;

    NSRange searchRange = NSMakeRange(0, [item length]);
    for (NSString *substring in substrings)
    {
        NSRange substringRange = [item rangeOfString:substring options:0 range:searchRange];
        if (substringRange.location == NSNotFound)
            return NO;
        searchRange.location = substringRange.location + substringRange.length;
        searchRange.length = [item length] - searchRange.location;
    }
    return YES;
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendList:substrings start:@"a string containing " separator:@", " end:@" in order"];
}

@end

id HC_stringContainsInOrder(NSString *substring, ...)
{
    va_list args;
    va_start(args, substring);
    NSArray *substrings = HCCollectItems(substring, args);
    va_end(args);

    return [HCStringContainsInOrder containsInOrder:substrings];
}
