//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCHasCount : HCBaseMatcher

+ (instancetype)hasCount:(id <HCMatcher>)matcher;
- (instancetype)initWithCount:(id <HCMatcher>)matcher;

@end


FOUNDATION_EXPORT id HC_hasCount(id <HCMatcher> matcher);

#ifdef HC_SHORTHAND
/*!
 * @brief hasCount(aMatcher) -
 * Matches if object's <code>-count</code> satisfies a given matcher.
 * @param aMatcher The matcher to satisfy.
 * @discussion This matcher invokes <code>-count</code> on the evaluated object to get the number of
 * elements it contains, passing the result to <em>aMatcher</em> for evaluation.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym HC_hasCount instead.
 */
#define hasCount HC_hasCount
#endif


FOUNDATION_EXPORT id HC_hasCountOf(NSUInteger count);

#ifdef HC_SHORTHAND
/*!
 * @brief hasCountOf(value) -
 * Matches if object's <code>-count</code> equals a given value.
 * @param value NSUInteger value to compare against as the expected value.
 * @discussion This matcher invokes <code>-count</code> on the evaluated object to get the number of
 * elements it contains, comparing the result to value for equality.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym HC_hasCountOf instead.
 */
#define hasCountOf HC_hasCountOf
#endif
