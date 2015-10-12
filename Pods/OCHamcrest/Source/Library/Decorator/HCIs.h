//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIs : HCBaseMatcher

+ (instancetype)is:(id <HCMatcher>)matcher;
- (instancetype)initWithMatcher:(id <HCMatcher>)matcher;

@end


FOUNDATION_EXPORT id HC_is(id match);

#ifdef HC_SHORTHAND
/*!
 * @brief is(aMatcher) -
 * Decorates another matcher, or provides a shortcut to the frequently used <code>is(equalTo(x))</code>.
 * @param aMatcher The matcher to satisfy, or an expected value for @ref equalTo matching.
 * @discussion This matcher compares the evaluated object to the given matcher.
 *
 * If <em>aMatcher</em>is a matcher, its behavior is retained, but the test may be more expressive.
 * For example:
 * <ul>
 *   <li><code>assertThat(\@(value), equalTo(\@5))</code></li>
 *   <li><code>assertThat(\@(value), is(equalTo(\@5)))</code></li>
 * </ul>
 *
 * If <em>aMatcher</em>is not a matcher, it is wrapped in an @ref equalTo matcher. This makes the
 * following statements equivalent:
 * <ul>
 *   <li><code>assertThat(cheese, equalTo(smelly))</code></li>
 *   <li><code>assertThat(cheese, is(equalTo(smelly)))</code></li>
 *   <li><code>assertThat(cheese, is(smelly))</code></li>
 * </ul>
 *
 * Choose the style that makes your expression most readable. This will vary depending on context.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_is instead.
 */
#define is HC_is
#endif
