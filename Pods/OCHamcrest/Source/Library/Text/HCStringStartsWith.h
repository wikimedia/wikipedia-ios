//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCSubstringMatcher.h>


@interface HCStringStartsWith : HCSubstringMatcher

+ (id)stringStartsWith:(NSString *)aSubstring;

@end


FOUNDATION_EXPORT id HC_startsWith(NSString *aSubstring);

#ifdef HC_SHORTHAND
/*!
 * @brief startsWith(aString) -
 * Matches if object is a string starting with a given string.
 * @param aString The string to search for. This value must not be <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it checks
 * if <em>aString</em> matches the beginning characters of the evaluated object.
 *
 * Example:
 * <ul>
 *   <li><code>endsWith(\@"foo")</code></li>
 * </ul>
 * will match "foobar".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_startsWith instead.
 */
#define startsWith HC_startsWith
#endif
