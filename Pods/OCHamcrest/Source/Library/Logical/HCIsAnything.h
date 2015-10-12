//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsAnything : HCBaseMatcher
{
    NSString *description;
}

+ (instancetype)isAnything;
+ (instancetype)isAnythingWithDescription:(NSString *)aDescription;

- (instancetype)init;
- (instancetype)initWithDescription:(NSString *)aDescription;

@end


FOUNDATION_EXPORT id HC_anything(void);

#ifdef HC_SHORTHAND
/*!
 * @brief Matches anything.
 * @discussion This matcher always evaluates to <code>YES</code>. Specify this in composite matchers
 * when the value of a particular element is unimportant.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_anything instead.
 */
#define anything() HC_anything()
#endif


FOUNDATION_EXPORT id HC_anythingWithDescription(NSString *aDescription);

#ifdef HC_SHORTHAND
/*!
 * @brief anythingWithDescription(description) -
 * Matches anything.
 * @param description A string used to describe this matcher.
 * @discussion This matcher always evaluates to <code>YES</code>. Specify this in collection
 * matchers when the value of a particular element in a collection is unimportant.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_anything instead.
 */
#define anythingWithDescription HC_anythingWithDescription
#endif
