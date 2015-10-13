//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCClassMatcher.h>


@interface HCIsInstanceOf : HCClassMatcher

+ (id)isInstanceOf:(Class)aClass;

@end


FOUNDATION_EXPORT id HC_instanceOf(Class aClass);

#ifdef HC_SHORTHAND
/*!
 * @brief instanceOf(aClass) -
 * Matches if object is an instance of, or inherits from, a given class.
 * @param aClass The class to compare against as the expected class.
 * @discussion This matcher checks whether the evaluated object is an instance of <em>aClass</em> or
 * an instance of any class that inherits from <em>aClass</em>.
 *
 * Example:
 * <ul>
 *   <li></code>instanceOf([NSString class])</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_instanceOf instead.
 */
#define instanceOf HC_instanceOf
#endif
