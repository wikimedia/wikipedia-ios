//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCStringContainsInOrder : HCBaseMatcher
{
    NSArray *substrings;
}

+ (instancetype)containsInOrder:(NSArray *)substringList;
- (instancetype)initWithSubstrings:(NSArray *)substringList;

@end


FOUNDATION_EXPORT id HC_stringContainsInOrder(NSString *substring, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief stringContainsInOrder(firstString, ...) -
 * Matches if object is a string containing a given list of substrings in relative order.
 * @param firstString,... A comma-separated list of strings ending with <code>nil</code>.
 * @discussion This matcher first checks whether the evaluated object is a string. If so, it checks
 * whether it contains a given list of strings, in relative order to each other. The searches are
 * performed starting from the beginning of the evaluated string.
 *
 * Example:
 * <ul>
 *   <li><code>stringContainsInOrder(\@"bc", \@"fg", \@"jkl", nil)</code></li>
 * </ul>
 * will match "abcdefghijklm".
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_stringContainsInOrder instead.
 */
#define stringContainsInOrder HC_stringContainsInOrder
#endif
