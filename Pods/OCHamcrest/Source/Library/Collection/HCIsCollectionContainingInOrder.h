//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCIsCollectionContainingInOrder : HCDiagnosingMatcher

+ (instancetype)isCollectionContainingInOrder:(NSArray *)itemMatchers;
- (instancetype)initWithMatchers:(NSArray *)itemMatchers;

@end


FOUNDATION_EXPORT id HC_contains(id itemMatch, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief contains(firstMatcher, ...) -
 * Matches if collection's elements satisfy a given list of matchers, in order.
 * @param firstMatcher,... A comma-separated list of matchers ending with <code>nil</code>.
 * @discussion This matcher iterates the evaluated collection and a given list of matchers, seeing
 * if each element satisfies its corresponding matcher.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_contains instead.)
 */
    #define contains HC_contains
#endif
