//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCIsEqualToNumber.h"

#import "HCIsEqual.h"


FOUNDATION_EXPORT id HC_equalToChar(char value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToDouble(double value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToFloat(float value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToInt(int value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToLong(long value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToLongLong(long long value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToShort(short value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedChar(unsigned char value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedInt(unsigned int value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedLong(unsigned long value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedLongLong(unsigned long long value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedShort(unsigned short value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToInteger(NSInteger value)
{
    return HC_equalTo(@(value));
}

FOUNDATION_EXPORT id HC_equalToUnsignedInteger(NSUInteger value)
{
    return HC_equalTo(@(value));
}

#pragma mark -

static NSString *stringForBool(BOOL value)
{
    return value ? @"<YES>" : @"<NO>";
}

FOUNDATION_EXPORT id HC_equalToBool(BOOL value)
{
    return [[HCIsEqualToBool alloc] initWithValue:value];
}

@implementation HCIsEqualToBool

static void HCRequireYesOrNo(BOOL value)
{
    if (value != YES && value != NO)
    {
        @throw [NSException exceptionWithName:@"BoolValue"
                                       reason:@"Must be YES or NO"
                                     userInfo:nil];
    }
}

- (instancetype)initWithValue:(BOOL)value
{
    HCRequireYesOrNo(value);

    self = [super init];
    if (self)
        _value = value;
    return self;
}

- (BOOL)matches:(id)item
{
    if (![item isKindOfClass:[NSNumber class]])
        return NO;

    return [item boolValue] == self.value;
}

- (void)describeTo:(id<HCDescription>)description
{
    [[description appendText:@"a BOOL with value "]
                  appendText:stringForBool(self.value)];
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    [mismatchDescription appendText:@"was "];
    if ([item isKindOfClass:[NSNumber class]])
        [mismatchDescription appendText:stringForBool([item boolValue])];
    else
        [mismatchDescription appendDescriptionOf:item];
}

@end
