//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCSubstringMatcher.h>


@interface HCStringContains : HCSubstringMatcher

+ (id)stringContains:(NSString *)aSubstring;

@end


FOUNDATION_EXPORT id HC_containsString(NSString *aSubstring) __attribute__((deprecated));

#ifdef HC_SHORTHAND
/*!
 * @brief containsString(aString) -
 * Matches if object is a string containing a given string.
 * @param aString The string to search for. This value must not be <code>nil</code>.
 * @discussion <em>Deprecated: Use @ref containsSubstring() instead.</em>
 *
 * This matcher first checks whether the evaluated object is a string. If so, it checks whether it
 * contains <em>aString</em>.
 *
 * Example:
 * <ul>
 *   <li><code>containsString(\@"def")</code></li>
 * </ul>
 * will match "abcdefg".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_containsString instead.
 */
#define containsString HC_containsString
#endif


FOUNDATION_EXPORT id HC_containsSubstring(NSString *aSubstring);

#ifdef HC_SHORTHAND
/*!
 * @brief containsSubstring(aString) -
 * Matches if object is a string containing a given string.
 * @param aString The string to search for. This value must not be <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it checks
 * whether it contains <em>aString</em>.
 *
 * Example:
 * <ul>
 *   <li><code>containsSubstring(\@"def")</code></li>
 * </ul>
 * will match "abcdefg".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_containsSubstring instead.
 */
#define containsSubstring HC_containsSubstring
#endif
