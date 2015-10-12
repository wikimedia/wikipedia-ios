//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsTrue : HCBaseMatcher
@end

@interface HCIsFalse : HCBaseMatcher
@end


FOUNDATION_EXPORT id HC_isTrue(void);

#ifdef HC_SHORTHAND
/*!
 * @brief Matches if object is equal to NSNumber with non-zero value.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isTrue instead.
 */
#define isTrue() HC_isTrue()
#endif


FOUNDATION_EXPORT id HC_isFalse(void);

#ifdef HC_SHORTHAND
/*!
 * @brief Matches if object is equal to NSNumber with zero value.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isFalse instead.
*/
#define isFalse() HC_isFalse()
#endif
