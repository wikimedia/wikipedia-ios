//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCEvery.h>


@interface HCIsCollectionOnlyContaining : HCEvery

+ (instancetype)isCollectionOnlyContaining:(id <HCMatcher>)matcher;

@end


FOUNDATION_EXPORT id HC_onlyContains(id itemMatch, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief onlyContains(firstMatcher, ...) -
 * Matches if each element of collection satisfies any of the given matchers.
 * @param firstMatcher,... A comma-separated list of matchers ending with <code>nil</code>.
 * @discussion This matcher iterates the evaluated collection, confirming whether each element
 * satisfies any of the given matchers.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * Example:
 * <ul>
 *   <li><code>onlyContains(startsWith(\@"Jo"), nil)</code></li>
 * </ul>
 * will match a collection ["Jon", "John", "Johann"].
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_onlyContains instead.
 */
#define onlyContains HC_onlyContains
#endif
