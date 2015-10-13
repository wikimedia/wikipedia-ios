//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>

@protocol HCMatcher;

/*!
 * @header
 * Assertion macros for using matchers in testing frameworks.
 * Unmet assertions are reported to the @ref HCTestFailureReporterChain.
 */


FOUNDATION_EXPORT void HC_assertThatWithLocation(id testCase, id actual, id <HCMatcher> matcher,
                                                 const char *fileName, int lineNumber);

#define HC_assertThat(actual, matcher)  \
    HC_assertThatWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThat(actual, matcher) -
 * Asserts that actual value satisfies matcher.
 * @param actual The object to evaluate as the actual value.
 * @param matcher The matcher to satisfy as the expected condition.
 * @discussion assertThat passes the actual value to the matcher for evaluation. If the matcher is
 * not satisfied, it is reported to the @ref HCTestFailureReporterChain.
 *
 * Use assertThat in test case methods. It's designed to integrate with XCTest and other testing
 * frameworks where individual tests are executed as methods.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThat instead.
 */
#define assertThat HC_assertThat
#endif


typedef id (^HCAssertThatAfterActualBlock)() __attribute__((deprecated));

OBJC_EXPORT void HC_assertThatAfterWithLocation(id testCase, NSTimeInterval maxTime,
                                                HCAssertThatAfterActualBlock actualBlock,
                                                id<HCMatcher> matcher,
                                                const char *fileName, int lineNumber) __attribute__((deprecated));

#define HC_assertThatAfter(maxTime, actualBlock, matcher)  \
    HC_assertThatAfterWithLocation(self, maxTime, actualBlock, matcher, __FILE__, __LINE__)

#define HC_futureValueOf(actual) ^{ return actual; }

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatAfter(maxTime, actualBlock, matcher) -
 * Asserts that a value provided by a block will satisfy matcher in less than a given time.
 * @param maxTime Max time (in seconds) in which the matcher has to be satisfied.
 * @param actualBlock A block providing the object to evaluate until timeout or the matcher is satisfied.
 * @param matcher The matcher to satisfy as the expected condition.
 * @deprecated Version 4.2.0. Use @ref assertWithTimeout instead.
 * @discussion assertThatAfter checks several times if the matcher is satisfied before timeout. To
 * evaluate the matcher, the <em>actualBlock</em> will provide updated values of actual. If the
 * matcher is not satisfied after <em>maxTime</em>, it is reported to the @ref HCTestFailureReporterChain.
 *
 * An easy way of defining the actualBlock is using the macro <code>futureValueOf(actual)</code>,
 * which also improves readability.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatAfter instead.
*/
#define assertThatAfter HC_assertThatAfter

/*!
 * @brief futureValueOf(actual) -
 * Evaluates actual value at future time.
 * @param actual The object to evaluate as the actual value.
 * @deprecated Version 4.2.0. Use @ref thatEventually instead.
 * @discussion Wraps <em>actual</em> in a block so that it can be repeatedly evaluated by @ref assertThatAfter.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_futureValueOf instead.
 */
#define futureValueOf HC_futureValueOf
#endif


typedef id (^HCFutureValue)();

OBJC_EXPORT void HC_assertWithTimeoutAndLocation(id testCase, NSTimeInterval timeout,
        HCFutureValue actualBlock,
        id <HCMatcher> matcher,
        const char *fileName, int lineNumber);

#define HC_assertWithTimeout(timeout, actualBlock, matcher)  \
    HC_assertWithTimeoutAndLocation(self, timeout, actualBlock, matcher, __FILE__, __LINE__)

#define HC_thatEventually(actual) ^{ return actual; }

#ifdef HC_SHORTHAND
/*!
 * @brief assertWithTimeout(timeout, actualBlock, matcher) -
 * Asserts that a value provided by a block will satisfy matcher within a given time.
 * @param timeout Maximum time to wait for passing behavior, specified in seconds.
 * @param actualBlock A block providing the object to repeatedly evaluate as the actual value.
 * @param matcher The matcher to satisfy as the expected condition.
 * @discussion <em>assertWithTimeout</em> polls a value provided by a block to asynchronously
 * satisfy the matcher. The block is evaluated repeatedly for an actual value, which is passed to
 * the matcher for evaluation. If the matcher is not satisfied within the timeout, it is reported to
 * the @ref HCTestFailureReporterChain.
 *
 * An easy way of providing the <em>actualBlock</em> is to use the macro @ref thatEventually</code>.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertWithTimeout instead.
*/
#define assertWithTimeout HC_assertWithTimeout


/*!
 * @brief thatEventually(actual) -
 * Evaluates actual value at future time.
 * @param actual The object to evaluate as the actual value.
 * @discussion Wraps <em>actual</em> in a block so that it can be repeatedly evaluated by @ref assertWithTimeout.
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_thatEventually instead.
 */
#define thatEventually HC_thatEventually
#endif
