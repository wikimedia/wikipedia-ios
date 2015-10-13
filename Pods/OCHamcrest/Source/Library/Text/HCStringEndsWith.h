//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCSubstringMatcher.h>


@interface HCStringEndsWith : HCSubstringMatcher

+ (id)stringEndsWith:(NSString *)aSubstring;

@end


FOUNDATION_EXPORT id HC_endsWith(NSString *aSubstring);

#ifdef HC_SHORTHAND
/*!
 * @brief endsWith(aString) -
 * Matches if object is a string ending with a given string.
 * @param aString The string to search for. This value must not be <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it checks
 * if <em>aString</em> matches the ending characters of the evaluated object.
 *
 * Example:
 * <ul>
 *   <li><code>endsWith(\@"bar")</code></li>
 * </ul>
 * will match "foobar".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_endsWith instead.
 */
#define endsWith HC_endsWith
#endif
