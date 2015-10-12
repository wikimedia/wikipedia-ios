//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsDictionaryContainingValue : HCBaseMatcher

+ (instancetype)isDictionaryContainingValue:(id <HCMatcher>)valueMatcher;
- (instancetype)initWithValueMatcher:(id <HCMatcher>)valueMatcher;

@end


FOUNDATION_EXPORT id HC_hasValue(id valueMatch);

#ifdef HC_SHORTHAND
/*!
 * @brief hasValue(valueMatcher) -
 * Matches if dictionary contains an entry whose value satisfies a given matcher.
 * @param valueMatcher The matcher to satisfy for the value, or an expected value for @ref equalTo matching.
 * @discussion This matcher iterates the evaluated dictionary, searching for any key-value entry
 * whose value satisfies the given matcher. If a matching entry is found, hasValue is satisfied.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * Examples:
 * <ul>
 *   <li><code>hasValue(equalTo(\@"bar"))</code></li>
 *   <li><code>hasValue(\@"bar")<code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasValue instead.
 */
#define hasValue HC_hasValue
#endif
