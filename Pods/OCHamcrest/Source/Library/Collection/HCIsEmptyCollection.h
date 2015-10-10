//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCHasCount.h>


@interface HCIsEmptyCollection : HCHasCount

+ (instancetype)isEmptyCollection;
- (instancetype)init;

@end


FOUNDATION_EXPORT id HC_isEmpty(void);

#ifdef HC_SHORTHAND
/*!
 * @brief Matches empty collection.
 * @discussion This matcher invokes <code>-count</code> on the evaluated object to determine if the
 * number of elements it contains is zero.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isEmpty instead.
 */
#define isEmpty() HC_isEmpty()
#endif
