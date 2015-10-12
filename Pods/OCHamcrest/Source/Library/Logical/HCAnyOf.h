//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCAnyOf : HCBaseMatcher

+ (instancetype)anyOf:(NSArray *)matchers;
- (instancetype)initWithMatchers:(NSArray *)matchers;

@end


FOUNDATION_EXPORT id HC_anyOf(id match, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief anyOf(firstMatcher, ...) -
 * Matches if any of the given matchers evaluate to <code>YES</code>.
 * @param firstMatcher,... A comma-separated list of matchers ending with <code>nil</code>.
 * @discussion The matchers are evaluated from left to right using short-circuit evaluation, so
 * evaluation stops as soon as a matcher returns <code>YES</code>.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_anyOf instead.
 */
#define anyOf HC_anyOf
#endif
