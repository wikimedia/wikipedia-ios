//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsDictionaryContaining : HCBaseMatcher

+ (instancetype)isDictionaryContainingKey:(id <HCMatcher>)keyMatcher
                                    value:(id <HCMatcher>)valueMatcher;

- (instancetype)initWithKeyMatcher:(id <HCMatcher>)keyMatcher
                      valueMatcher:(id <HCMatcher>)valueMatcher;

@end


FOUNDATION_EXPORT id HC_hasEntry(id keyMatch, id valueMatch);

#ifdef HC_SHORTHAND
/*!
 * @brief hasEntry(keyMatcher, valueMatcher) -
 * Matches if dictionary contains key-value entry satisfying a given pair of matchers.
 * @param keyMatcher The matcher to satisfy for the key, or an expected value for @ref equalTo matching.
 * @param valueMatcher The matcher to satisfy for the value, or an expected value for @ref equalTo matching.
 * @discussion This matcher iterates the evaluated dictionary, searching for any key-value entry
 * that satisfies <em>keyMatcher</em> and <em>valueMatcher</em>. If a matching entry is found,
 * hasEntry is satisfied.
 *
 * Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
 * equality.
 *
 * Examples:
 * <ul>
 *   <li><code>hasEntry(equalTo(\@"foo"), equalTo(\@"bar"))</code></li>
 *   <li><code>hasEntry(\@"foo", \@"bar")</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasEntry instead.
 */
#define hasEntry HC_hasEntry
#endif
