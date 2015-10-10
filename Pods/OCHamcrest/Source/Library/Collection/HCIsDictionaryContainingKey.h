//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsDictionaryContainingKey : HCBaseMatcher

+ (instancetype)isDictionaryContainingKey:(id <HCMatcher>)keyMatcher;
- (instancetype)initWithKeyMatcher:(id <HCMatcher>)keyMatcher;

@end


FOUNDATION_EXPORT id HC_hasKey(id keyMatch);

#ifdef HC_SHORTHAND
/*!
 * @brief hasKey(keyMatcher) -
 * Matches if dictionary contains an entry whose key satisfies a given matcher.
 * @param keyMatcher The matcher to satisfy for the key, or an expected value for @ref equalTo matching.
 * @discussion This matcher iterates the evaluated dictionary, searching for any key-value entry
 * whose key satisfies the given matcher. If a matching entry is found, hasKey is satisfied.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * Examples:
 * <ul>
 *   <li><code>hasEntry(equalTo(\@"foo"))</code></li>
 *   <li><code>hasEntry(\@"foo")</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasKey instead.
 */
#define hasKey HC_hasKey
#endif
