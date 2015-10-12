//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCOrderingComparison : HCBaseMatcher

+ (instancetype)compare:(id)expectedValue
             minCompare:(NSComparisonResult)min
             maxCompare:(NSComparisonResult)max
  comparisonDescription:(NSString *)comparisonDescription;

- (instancetype)initComparing:(id)expectedValue
                   minCompare:(NSComparisonResult)min
                   maxCompare:(NSComparisonResult)max
        comparisonDescription:(NSString *)comparisonDescription;

@end


FOUNDATION_EXPORT id HC_greaterThan(id expected);

#ifdef HC_SHORTHAND
/*!
 * @brief greaterThan(aNumber) -
 * Matches if object is greater than a given number.
 * @param aNumber The NSNumber to compare against.
 * @discussion Example:
 * <ul>
 *   <li><code>greaterThan(\@5)</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_greaterThan instead.
 */
#define greaterThan HC_greaterThan
#endif


FOUNDATION_EXPORT id HC_greaterThanOrEqualTo(id expected);

#ifdef HC_SHORTHAND
/*!
 * @brief greaterThanOrEqualTo(aNumber) -
 * Matches if object is greater than or equal to a given number.
 * @param aNumber The NSNumber to compare against.
 * @discussion Example:
 * <ul>
 *   <li><code>greaterThanOrEqualTo(\@5)</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_greaterThanOrEqualTo instead.
 */
#define greaterThanOrEqualTo HC_greaterThanOrEqualTo
#endif


FOUNDATION_EXPORT id HC_lessThan(id expected);

#ifdef HC_SHORTHAND
/*!
 * @brief lessThan(aNumber) -
 * Matches if object is less than a given number.
 * @param aNumber The NSNumber to compare against.
 * @discussion Example:
 * <ul>
 *   <li><code>lessThan(\@5)</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_lessThan instead.
 */
#define lessThan HC_lessThan
#endif


FOUNDATION_EXPORT id HC_lessThanOrEqualTo(id expected);

#ifdef HC_SHORTHAND
/*!
 * @brief lessThanOrEqualTo(aNumber) -
 * Matches if object is less than or equal to a given number.
 * @param aNumber The NSNumber to compare against.
 * @discussion Example:
 * <ul>
 *   <li><code>lessThanOrEqualTo(\@5)</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_lessThanOrEqualTo instead.
 */
#define lessThanOrEqualTo HC_lessThanOrEqualTo
#endif
