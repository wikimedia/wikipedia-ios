//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCDescribedAs : HCBaseMatcher

+ (instancetype)describedAs:(NSString *)description
                 forMatcher:(id <HCMatcher>)matcher
                 overValues:(NSArray *)templateValues;

- (instancetype)initWithDescription:(NSString *)description
                         forMatcher:(id <HCMatcher>)matcher
                         overValues:(NSArray *)templateValues;

@end


FOUNDATION_EXPORT id HC_describedAs(NSString *description, id <HCMatcher> matcher, ...) NS_REQUIRES_NIL_TERMINATION;

#ifdef HC_SHORTHAND
/*!
 * @brief describedAs(description, matcher, ...) -
 * Adds custom failure description to a given matcher.
 * @param description Overrides the matcher's description.
 * @param matcher,... The matcher to satisfy, followed by a comma-separated list of substitution
 * values ending with <code>nil</code>.
 * @discussion The description may contain substitution placeholders %0, %1, etc. These will be
 * replaced by any values that follow the matcher.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_describedAs instead.
 */
#define describedAs HC_describedAs
#endif
