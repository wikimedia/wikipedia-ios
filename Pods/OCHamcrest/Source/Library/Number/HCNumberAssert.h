//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>

@protocol HCMatcher;


FOUNDATION_EXPORT void HC_assertThatBoolWithLocation(id testCase, BOOL actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatBool(actual, matcher)  \
    HC_assertThatBoolWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatBool(actual, matcher) -
 * Asserts that BOOL actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The BOOL value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatBool instead.
 */
#define assertThatBool HC_assertThatBool
#endif


FOUNDATION_EXPORT void HC_assertThatCharWithLocation(id testCase, char actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatChar(actual, matcher)  \
    HC_assertThatCharWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatChar(actual, matcher) -
 * Asserts that char actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The char value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatChar instead.
 */
#define assertThatChar HC_assertThatChar
#endif


FOUNDATION_EXPORT void HC_assertThatDoubleWithLocation(id testCase, double actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatDouble(actual, matcher)  \
    HC_assertThatDoubleWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief HC_assertThatDouble(actual, matcher) -
 * Asserts that double actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The double value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatDouble instead.
 */
#define assertThatDouble HC_assertThatDouble
#endif


FOUNDATION_EXPORT void HC_assertThatFloatWithLocation(id testCase, float actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatFloat(actual, matcher)  \
    HC_assertThatFloatWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatFloat(actual, matcher) -
 * Asserts that float actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The float value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatFloat instead.
 */
#define assertThatFloat HC_assertThatFloat
#endif


FOUNDATION_EXPORT void HC_assertThatIntWithLocation(id testCase, int actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatInt(actual, matcher)  \
    HC_assertThatIntWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatInt(actual, matcher) -
 * Asserts that int actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The int value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatInt instead.
 */
#define assertThatInt HC_assertThatInt
#endif


FOUNDATION_EXPORT void HC_assertThatLongWithLocation(id testCase, long actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatLong(actual, matcher)  \
    HC_assertThatLongWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatLong(actual, matcher) -
 * Asserts that long actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The long value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatLong instead.
 */
#define assertThatLong HC_assertThatLong
#endif


FOUNDATION_EXPORT void HC_assertThatLongLongWithLocation(id testCase, long long actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatLongLong(actual, matcher)  \
    HC_assertThatLongLongWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatLongLong(actual, matcher) -
 * Asserts that <code>long long</code> actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The long long value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatLongLong instead.
 */
#define assertThatLongLong HC_assertThatLongLong
#endif


FOUNDATION_EXPORT void HC_assertThatShortWithLocation(id testCase, short actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatShort(actual, matcher)  \
    HC_assertThatShortWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatShort(actual, matcher) -
 * Asserts that short actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The short value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatShort instead.
 */
#define assertThatShort HC_assertThatShort
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedCharWithLocation(id testCase, unsigned char actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedChar(actual, matcher)  \
    HC_assertThatUnsignedCharWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedChar(actual, matcher) -
 * Asserts that unsigned char actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The unsigned char value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedChar instead.
 */
#define assertThatUnsignedChar HC_assertThatUnsignedChar
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedIntWithLocation(id testCase, unsigned int actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedInt(actual, matcher)  \
    HC_assertThatUnsignedIntWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedInt(actual, matcher) -
 * Asserts that unsigned int actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The unsigned int value to convert to an NSNumber for evaluation.
 * @param matcher  The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedInt instead.
 */
#define assertThatUnsignedInt HC_assertThatUnsignedInt
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedLongWithLocation(id testCase, unsigned long actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedLong(actual, matcher)  \
    HC_assertThatUnsignedLongWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedLong(actual, matcher) -
 * Asserts that unsigned long actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The unsigned long value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedLong instead.
 */
#define assertThatUnsignedLong HC_assertThatUnsignedLong
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedLongLongWithLocation(id testCase, unsigned long long actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedLongLong(actual, matcher)  \
    HC_assertThatUnsignedLongLongWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedLongLong(actual, matcher) -
 * Asserts that unsigned long long actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The unsigned long long value to convert to an NSNumber for evaluation.
 * @param matcher  The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedLongLong instead.
 */
#define assertThatUnsignedLongLong HC_assertThatUnsignedLongLong
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedShortWithLocation(id testCase, unsigned short actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedShort(actual, matcher)  \
    HC_assertThatUnsignedShortWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedShort(actual, matcher) -
 * Asserts that unsigned short actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The unsigned short value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedShort instead.
 */
#define assertThatUnsignedShort HC_assertThatUnsignedShort
#endif


FOUNDATION_EXPORT void HC_assertThatIntegerWithLocation(id testCase, NSInteger actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatInteger(actual, matcher)  \
    HC_assertThatIntegerWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatInteger(actual, matcher) -
 * Asserts that NSInteger actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The NSInteger value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatInteger instead.
 */
#define assertThatInteger HC_assertThatInteger
#endif


FOUNDATION_EXPORT void HC_assertThatUnsignedIntegerWithLocation(id testCase, NSUInteger actual,
        id <HCMatcher> matcher, char const *fileName, int lineNumber);

#define HC_assertThatUnsignedInteger(actual, matcher)  \
    HC_assertThatUnsignedIntegerWithLocation(self, actual, matcher, __FILE__, __LINE__)

#ifdef HC_SHORTHAND
/*!
 * @brief assertThatUnsignedInteger(actual, matcher) -
 * Asserts that NSUInteger actual value, converted to an NSNumber, satisfies matcher.
 * @param actual The NSUInteger value to convert to an NSNumber for evaluation.
 * @param matcher The matcher to satisfy as the expected condition.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_assertThatUnsignedInteger instead.
 */
#define assertThatUnsignedInteger HC_assertThatUnsignedInteger
#endif
