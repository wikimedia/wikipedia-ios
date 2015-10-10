//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCClassMatcher.h>


@interface HCIsTypeOf : HCClassMatcher

+ (id)isTypeOf:(Class)aClass;

@end


FOUNDATION_EXPORT id HC_isA(Class aClass);

#ifdef HC_SHORTHAND
/*!
 * @brief isA(aClass) -
 * Matches if object is an instance of a given class (but not of a subclass).
 * @param aClass The class to compare against as the expected class.
 * This matcher checks whether the evaluated object is an instance of <em>aClass</em>.
 *
 * Example:
 * <ul>
 *   <li><code>isA([Foo class])</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isA instead.
 */
#define isA HC_isA
#endif
