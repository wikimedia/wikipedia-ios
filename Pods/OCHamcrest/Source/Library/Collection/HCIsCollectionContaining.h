//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCIsCollectionContaining : HCDiagnosingMatcher

+ (instancetype)isCollectionContaining:(id <HCMatcher>)elementMatcher;
- (instancetype)initWithMatcher:(id <HCMatcher>)elementMatcher;

@end


FOUNDATION_EXPORT id HC_hasItem(id itemMatch);

#ifdef HC_SHORTHAND
/*!
 * @brief hasItem(aMatcher) -
 * Matches if any element of collection satisfies a given matcher.
 * @param aMatcher The matcher to satisfy, or an expected value for @ref equalTo matching.
 * @discussion This matcher iterates the evaluated collection, searching for any element that
 * satisfies a given matcher. If a matching element is found, hasItem is satisfied.
 *
 * If <em>aMatcher</em> is not a matcher, it is implicitly wrapped in an @ref equalTo matcher to
 * check for equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasItem instead.
 */
#define hasItem HC_hasItem
#endif


FOUNDATION_EXPORT id HC_hasItems(id itemMatch, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief hasItems(firstMatcher, ...) -
 * Matches if all of the given matchers are satisfied by any elements of the collection.
 * @param firstMatcher,... A comma-separated list of matchers ending with <code>nil</code>.
 * @discussion This matcher iterates the given matchers, searching for any elements in the evaluated
 * collection that satisfy them. If each matcher is satisfied, then hasItems is satisfied.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasItems instead.
 */
#define hasItems HC_hasItems
#endif
