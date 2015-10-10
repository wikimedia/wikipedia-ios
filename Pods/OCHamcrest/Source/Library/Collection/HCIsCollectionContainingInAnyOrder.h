//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCIsCollectionContainingInAnyOrder : HCDiagnosingMatcher

+ (instancetype)isCollectionContainingInAnyOrder:(NSArray *)itemMatchers;
- (instancetype)initWithMatchers:(NSArray *)itemMatchers;

@end


FOUNDATION_EXPORT id HC_containsInAnyOrder(id itemMatch, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief containsInAnyOrder(firstMatcher, ...) -
 * Matches if collection's elements, in any order, satisfy a given list of matchers.
 * @param firstMatcher,... A comma-separated list of matchers ending with <code>nil</code>.
 * @discussion This matcher iterates the evaluated collection, seeing if each element satisfies any
 * of the given matchers. The matchers are tried from left to right, and when a satisfied matcher is
 * found, it is no longer a candidate for the remaining elements. If a one-to-one correspondence is
 * established between elements and matchers, containsInAnyOrder is satisfied.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_containsInAnyOrder instead.
 */
#define containsInAnyOrder HC_containsInAnyOrder
#endif
