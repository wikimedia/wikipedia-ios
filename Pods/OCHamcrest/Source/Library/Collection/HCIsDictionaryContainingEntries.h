//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCIsDictionaryContainingEntries : HCDiagnosingMatcher


+ (instancetype)isDictionaryContainingKeys:(NSArray *)keys
                             valueMatchers:(NSArray *)valueMatchers;

- (instancetype)initWithKeys:(NSArray *)keys
               valueMatchers:(NSArray *)valueMatchers;

@end


FOUNDATION_EXPORT id HC_hasEntries(id keysAndValueMatch, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief hasEntries(firstKey, valueMatcher, ...) -
 * Matches if dictionary contains entries satisfying a list of alternating keys and their value matchers.
 * @param firstKey A key (not a matcher) to look up.
 * @param valueMatcher,... The matcher to satisfy for the value, or an expected value for @ref equalTo matching.
 * @discussion Note that the keys must be actual keys, not matchers. Any value argument that is not
 * a matcher is implicitly wrapped in an @ref equalTo matcher to check for equality. The list must
 * end with <code>nil</code>.
 *
 * Examples:
 * <ul>
 *   <li><code>hasEntries(\@"first", equalTo(\@"Jon"), \@"last", equalTo(\@"Reid"), nil)</code></li>
 *   <li><code>hasEntries(\@"first", \@"Jon", \@"last", \@"Reid", nil)</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasEntry instead.
 */
#define hasEntries HC_hasEntries
#endif
