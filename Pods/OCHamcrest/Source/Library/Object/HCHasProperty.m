//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt
//  Contribution by Justin Shacklette

#import "HCHasProperty.h"

#import "HCRequireNonNilObject.h"
#import "HCWrapInMatcher.h"
#import "NSInvocation+OCHamcrest.h"


@interface HCHasProperty ()
@property (readonly, nonatomic, copy) NSString *propertyName;
@property (readonly, nonatomic, strong) id <HCMatcher> valueMatcher;
@end

@implementation HCHasProperty

+ (instancetype)hasProperty:(NSString *)property value:(id <HCMatcher>)valueMatcher
{
    return [[self alloc] initWithProperty:property value:valueMatcher];
}

- (instancetype)initWithProperty:(NSString *)property value:(id <HCMatcher>)valueMatcher
{
    HCRequireNonNilObject(property);

    self = [super init];
    if (self != nil)
    {
        _propertyName = [property copy];
        _valueMatcher = valueMatcher;
    }
    return self;
}

- (BOOL)matches:(id)item describingMismatchTo:(id <HCDescription>)mismatchDescription
{
    SEL propertyGetter = NSSelectorFromString(self.propertyName);
    if (![item respondsToSelector:propertyGetter])
    {
        [[[[mismatchDescription appendText:@"no "]
                                appendText:self.propertyName]
                                appendText:@" on "]
                                appendDescriptionOf:item];
        return NO;
    }

    NSInvocation *getterInvocation = [NSInvocation och_invocationWithTarget:item selector:propertyGetter];
    id propertyValue = [getterInvocation och_invoke];
    BOOL match =  [self.valueMatcher matches:propertyValue];
    if (!match)
    {
        [[[[[mismatchDescription appendText:self.propertyName]
                                 appendText:@" was "]
                                 appendDescriptionOf:propertyValue]
                                 appendText:@" on "]
                                 appendDescriptionOf:item];
    }
    return match;
}

- (void)describeTo:(id<HCDescription>)description
{
    [[[[description appendText:@"an object with "]
                    appendText:self.propertyName]
                    appendText:@" "]
                    appendDescriptionOf:self.valueMatcher];
}
@end


id HC_hasProperty(NSString *name, id valueMatch)
{
    return [HCHasProperty hasProperty:name value:HCWrapInMatcher(valueMatch)];
}
