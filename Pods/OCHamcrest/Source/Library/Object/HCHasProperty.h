//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt
//  Contribution by Justin Shacklette

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCHasProperty : HCDiagnosingMatcher

+ (instancetype)hasProperty:(NSString *)property value:(id <HCMatcher>)valueMatcher;
- (instancetype)initWithProperty:(NSString *)property value:(id <HCMatcher>)valueMatcher;

@end


FOUNDATION_EXPORT id HC_hasProperty(NSString *name, id valueMatch);

#ifdef HC_SHORTHAND
/*!
 * @brief hasProperty(name, valueMatcher) -
 * Matches if object has a method of a given name whose return value satisfies a given matcher.
 * @param name The name of a method without arguments that returns an object.
 * @param valueMatcher The matcher to satisfy for the return value, or an expected value for @ref equalTo matching.
 * @discussion This matcher first checks if the evaluated object has a method with a name matching
 * the given name. If so, it invokes the method and sees if the returned value satisfies <em>valueMatcher</em>.
 *
 * While this matcher is called "hasProperty", it's useful for checking the results of any simple
 * methods, not just properties.
 *
 * Examples:
 * <ul>
 *   <li><code>hasProperty(\@"firstName", \@"Joe")</code></li>
 *   <li><code>hasProperty(\@"firstName", startsWith(\@"J"))</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_hasProperty instead.
 */
    #define hasProperty HC_hasProperty
#endif
