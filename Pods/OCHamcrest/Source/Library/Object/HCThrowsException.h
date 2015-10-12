//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCDiagnosingMatcher.h>


@interface HCThrowsException : HCDiagnosingMatcher

- (id)initWithExceptionMatcher:(id)exceptionMatcher;

@end


FOUNDATION_EXPORT id HC_throwsException(id exceptionMatcher);

#ifdef HC_SHORTHAND
/*!
 * @brief throwsException(exceptionMatcher) -
 * Matches if object is a block which, when executed, throws an exception satisfying a given matcher.
 * @param exceptionMatcher The matcher to satisfy when passed the exception.
 * @discussion Example:
 * <ul>
 *   <li><code>throwsException(instanceOf([NSException class]))</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_throwsException instead.
 */
#define throwsException HC_throwsException
#endif
