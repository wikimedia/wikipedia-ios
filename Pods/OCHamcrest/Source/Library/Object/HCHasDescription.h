//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCInvocationMatcher.h>


@interface HCHasDescription : HCInvocationMatcher

+ (instancetype)hasDescription:(id <HCMatcher>)descriptionMatcher;
- (instancetype)initWithDescription:(id <HCMatcher>)descriptionMatcher;

@end


FOUNDATION_EXPORT id HC_hasDescription(id match);

#ifdef HC_SHORTHAND
/*!
 * @brief hasDescription(aMatcher) -
 * Matches if object's <code>-description</code> satisfies a given matcher.
 * @param aMatcher The matcher to satisfy, or an expected value for @ref equalTo matching.
 * @discussion This matcher invokes <code>-description</code> on the evaluated object to get its
 * description, passing the result to a given matcher for evaluation. If <em>aMatcher</em> is not a
 * matcher, it is implicitly wrapped in an @ref equalTo matcher to check for equality.
 *
 * Examples:
 * <ul>
 *   <li><code>hasDescription(startsWith(\@"foo"))</code></li>
 *   <li><code>hasDescription(\@"bar")</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasDescription instead.
 */
#define hasDescription HC_hasDescription
#endif
