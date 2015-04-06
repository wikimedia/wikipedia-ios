//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTDynamicProperties.h"

#import <objc/runtime.h>


@interface MKTDynamicProperties ()
@property (nonatomic, copy) NSDictionary *selectorToSignature;
@end

@implementation MKTDynamicProperties

+ (NSDictionary *)dynamicPropertySelectorsForClass:(Class)aClass
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (Class cls = aClass; cls != Nil; cls = [cls superclass])
    {
        NSDictionary *properties = [self dynamicPropertySelectorsForSingleClass:cls];
        [result addEntriesFromDictionary:properties];
    }
    return result;
}

+ (NSDictionary *)dynamicPropertySelectorsForSingleClass:(Class)aClass
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(aClass, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i)
        [self addSelectorsForDynamicProperty:properties[i] toDictionary:result];
    free(properties);
    return result;
}

+ (void)addSelectorsForDynamicProperty:(objc_property_t)aProperty toDictionary:(NSMutableDictionary *)dict
{
    BOOL isDynamic = [self isAttributeSet:"D" onProperty:aProperty];
    if (isDynamic)
        [self addSelectorsForProperty:aProperty toDictionary:dict];
}

+ (BOOL)isAttributeSet:(const char *)attributeName onProperty:(objc_property_t)aProperty
{
    char *attributeValue = property_copyAttributeValue(aProperty, attributeName);
    BOOL isSet = attributeValue != 0;
    free(attributeValue);
    return isSet;
}

+ (NSString *)attributeNamed:(const char *)attributeName onProperty:(objc_property_t)aProperty
{
    NSString *attributeString;
    char *attributeValue = property_copyAttributeValue(aProperty, attributeName);
    if (attributeValue)
        attributeString = [NSString stringWithUTF8String:attributeValue];
    free(attributeValue);
    return attributeString;
}

+ (void)addSelectorsForProperty:(objc_property_t)aProperty toDictionary:(NSMutableDictionary *)dict
{
    dict[ [self getterNameForProperty:aProperty] ] = [self getterSignatureForProperty:aProperty];
    BOOL isReadonly = [self isAttributeSet:"R" onProperty:aProperty];
    if (!isReadonly)
        dict[ [self setterNameForProperty:aProperty] ] = [self setterSignatureForProperty:aProperty];
}

+ (NSString *)getterNameForProperty:(objc_property_t)aProperty
{
    NSString *name = [self customGetterNameForProperty:aProperty];
    if (name)
        return name;
    return [self standardGetterNameForProperty:aProperty];
}

+ (NSString *)customGetterNameForProperty:(objc_property_t)aProperty
{
    return [self attributeNamed:"G" onProperty:aProperty];
}

+ (NSString *)standardGetterNameForProperty:(objc_property_t)aProperty
{
    return [NSString stringWithUTF8String:property_getName(aProperty)];
}

+ (NSString *)setterNameForProperty:(objc_property_t)aProperty
{
    NSString *name = [self customSetterNameForProperty:aProperty];
    if (name)
        return name;
    return [self standardSetterNameForProperty:aProperty];
}

+ (NSString *)customSetterNameForProperty:(objc_property_t)aProperty
{
    return [self attributeNamed:"S" onProperty:aProperty];
}

+ (NSString *)standardSetterNameForProperty:(objc_property_t)aProperty
{
    NSString *propertyName = [NSString stringWithUTF8String:property_getName(aProperty)];
    NSString *capitalizedFirstCharacter = [[propertyName substringToIndex:1] uppercaseString];
    NSString *capitalizedPropertyName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                              withString:capitalizedFirstCharacter];
    return [NSString stringWithFormat:@"set%@:", capitalizedPropertyName];
}

+ (NSMethodSignature *)getterSignatureForProperty:(objc_property_t)aProperty
{
    return [self signatureWithFormat:@"%@@:" forProperty:aProperty];
}

+ (NSMethodSignature *)setterSignatureForProperty:(objc_property_t)aProperty
{
    return [self signatureWithFormat:@"v@:%@" forProperty:aProperty];
}

+ (NSMethodSignature *)signatureWithFormat:(NSString *)format forProperty:(objc_property_t)aProperty
{
    NSString *signatureTypes = [NSString stringWithFormat:format, [self propertyType:aProperty]];
    return [NSMethodSignature signatureWithObjCTypes:[signatureTypes UTF8String]];
}

+ (NSString *)propertyType:(objc_property_t)aProperty
{
    return [self attributeNamed:"T" onProperty:aProperty];
}

- (instancetype)initWithClass:(Class)aClass
{
    self = [super init];
    if (self)
        _selectorToSignature = [[[self class] dynamicPropertySelectorsForClass:aClass] copy];
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return self.selectorToSignature[ NSStringFromSelector(aSelector) ];
}

@end
