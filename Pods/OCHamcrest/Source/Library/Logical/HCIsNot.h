//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsNot : HCBaseMatcher

+ (instancetype)isNot:(id <HCMatcher>)matcher;
- (instancetype)initNot:(id <HCMatcher>)matcher;

@end


FOUNDATION_EXPORT id HC_isNot(id aMatcher);

#ifdef HC_SHORTHAND
/*!
 * @brief isNot(aMatcher) -
 * Inverts the given matcher to its logical negation.
 * @param aMatcher The matcher to negate.
 * @discussion This matcher compares the evaluated object to the negation of the given matcher. If
 * <em>aMatcher</em> is not a matcher, it is implicitly wrapped in an @ref equalTo matcher to check
 * for equality, and thus matches for inequality.
 *
 * Examples:
 * <ul>
 *   <li><code>assertThat(cheese, isNot(equalTo(smelly)))</code></li>
 *   <li><code>assertThat(cheese, isNot(smelly))</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isNot instead.
 */
#define isNot HC_isNot
#endif
