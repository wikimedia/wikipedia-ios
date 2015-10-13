//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsEqualIgnoringCase : HCBaseMatcher

+ (instancetype)isEqualIgnoringCase:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;

@end


FOUNDATION_EXPORT id HC_equalToIgnoringCase(NSString *aString);

#ifdef HC_SHORTHAND
/*!
 * @brief equalToIgnoringCase(string) -
 * Matches if object is a string equal to a given string, ignoring case differences.
 * @param aString The string to compare against as the expected value. This value must not be <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it
 * compares it with <em>aString</em>, ignoring differences of case.
 *
 * Example:
 * <ul>
 *   <li><code>equalToIgnoringCase(\@"hello world")</code></li>
 * </ul>
 * will match "heLLo WorlD".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_equalToIgnoringCase instead.
 */
#define equalToIgnoringCase HC_equalToIgnoringCase
#endif
