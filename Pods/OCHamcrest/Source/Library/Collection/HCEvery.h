//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCEvery : HCDiagnosingMatcher

@property (nonatomic, strong, readonly) id <HCMatcher> matcher;

- (instancetype)initWithMatcher:(id <HCMatcher>)matcher;

@end


FOUNDATION_EXPORT id HC_everyItem(id itemMatcher);

#ifdef HC_SHORTHAND
/*!
 * @brief everyItem(itemMatcher) -
 * Matches if every element of a collection satisfies the given matcher.
 * @param itemMatcher The matcher to apply to every item provided by the examined collection.
 * @discussion This matcher iterates the evaluated collection, confirming that each element
 * satisfies the given matcher.
 *
 * Example:
 * <ul>
 *   <li><code>everyItem(startsWith(\@"Jo"))</code></li>
 * </ul>
 * will match a collection ["Jon", "John", "Johann"].
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym HC_everyItem instead.
 */
#define everyItem HC_everyItem
#endif
