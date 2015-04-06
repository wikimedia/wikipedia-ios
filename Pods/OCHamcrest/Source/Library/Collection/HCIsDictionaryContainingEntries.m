//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCIsDictionaryContainingEntries.h"

#import "HCWrapInMatcher.h"


@interface HCIsDictionaryContainingEntries ()
@property (readonly, nonatomic, copy) NSArray *keys;
@property (readonly, nonatomic, copy) NSArray *valueMatchers;
@end


@implementation HCIsDictionaryContainingEntries

+ (instancetype)isDictionaryContainingKeys:(NSArray *)keys
                             valueMatchers:(NSArray *)valueMatchers
{
    return [[self alloc] initWithKeys:keys valueMatchers:valueMatchers];
}

- (instancetype)initWithKeys:(NSArray *)keys
               valueMatchers:(NSArray *)valueMatchers
{
    self = [super init];
    if (self)
    {
        _keys = [keys copy];
        _valueMatchers = [valueMatchers copy];
    }
    return self;
}

- (BOOL)matches:(id)dict describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    if (![dict isKindOfClass:[NSDictionary class]])
    {
        [[mismatchDescription appendText:@"was non-dictionary "] appendDescriptionOf:dict];
        return NO;
    }

    NSUInteger count = [self.keys count];
    for (NSUInteger index = 0; index < count; ++index)
    {
        id key = self.keys[index];
        if (dict[key] == nil)
        {
            [[[[mismatchDescription appendText:@"no "]
                                    appendDescriptionOf:key]
                                    appendText:@" key in "]
                                    appendDescriptionOf:dict];
            return NO;
        }

        id valueMatcher = self.valueMatchers[index];
        id actualValue = dict[key];

        if (![valueMatcher matches:actualValue])
        {
            [[[[mismatchDescription appendText:@"value for "]
                                    appendDescriptionOf:key]
                                    appendText:@" was "]
                                    appendDescriptionOf:actualValue];
            return NO;
        }
    }

    return YES;
}

- (void)describeKeyValueAtIndex:(NSUInteger)index to:(id<HCDescription>)description
{
    [[[[description appendDescriptionOf:self.keys[index]]
                    appendText:@" = "]
                    appendDescriptionOf:self.valueMatchers[index]]
                    appendText:@"; "];
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendText:@"a dictionary containing { "];
    NSUInteger count = [self.keys count];
    NSUInteger index = 0;
    for (; index < count - 1; ++index)
        [self describeKeyValueAtIndex:index to:description];
    [self describeKeyValueAtIndex:index to:description];
    [description appendText:@"}"];
}

@end


static void requirePairedObject(id obj)
{
    if (obj == nil)
    {
        @throw [NSException exceptionWithName:@"NilObject"
                                       reason:@"HC_hasEntries keys and value matchers must be paired"
                                     userInfo:nil];
    }
}


id HC_hasEntries(id keysAndValueMatch, ...)
{
    va_list args;
    va_start(args, keysAndValueMatch);

    id key = keysAndValueMatch;
    id valueMatcher = va_arg(args, id);
    requirePairedObject(valueMatcher);
    NSMutableArray *keys = [NSMutableArray arrayWithObject:key];
    NSMutableArray *valueMatchers = [NSMutableArray arrayWithObject:HCWrapInMatcher(valueMatcher)];

    key = va_arg(args, id);
    while (key != nil)
    {
        [keys addObject:key];
        valueMatcher = va_arg(args, id);
        requirePairedObject(valueMatcher);
        [valueMatchers addObject:HCWrapInMatcher(valueMatcher)];
        key = va_arg(args, id);
    }

    return [HCIsDictionaryContainingEntries isDictionaryContainingKeys:keys
                                                         valueMatchers:valueMatchers];
}
