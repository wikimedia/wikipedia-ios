//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsEqualIgnoringWhiteSpace : HCBaseMatcher

+ (instancetype)isEqualIgnoringWhiteSpace:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;

@end


FOUNDATION_EXPORT id HC_equalToIgnoringWhiteSpace(NSString *aString);

#ifdef HC_SHORTHAND
/*!
 * @brief equalToIgnoringWhiteSpace(aString) -
 * Matches if object is a string equal to a given string, ignoring differences in whitespace.
 * @param aString The string to compare against as the expected value. This value must not be <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it
 * compares it with <em>aString</em>, ignoring differences in runs of whitespace.
 *
 * Example:
 * <ul>
 *   </li><code>equalToIgnoringWhiteSpace(\@"hello world")</code></li>
 * </ul>
 * will match <pre>"hello   world"</pre>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_equalToIgnoringWhiteSpace instead.
 */
#define equalToIgnoringWhiteSpace HC_equalToIgnoringWhiteSpace
#endif
