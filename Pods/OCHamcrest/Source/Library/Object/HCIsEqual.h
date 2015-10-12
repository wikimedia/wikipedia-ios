//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsEqual : HCBaseMatcher

+ (instancetype)isEqualTo:(id)object;
- (instancetype)initEqualTo:(id)object;

@end


FOUNDATION_EXPORT id HC_equalTo(id object);

#ifdef HC_SHORTHAND
/*!
 * @brief equalTo(anObject) -
 * Matches if object is equal to a given object.
 * @param anObject The object to compare against as the expected value.
 * @discussion This matcher compares the evaluated object to <em>anObject</em> for equality, as
 * determined by the <code>-isEqual:</code> method.
 *
 * If <em>anObject</em> is <code>nil</code>, the matcher will successfully match <code>nil</code>.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_equalTo instead.
 */
#define equalTo HC_equalTo
#endif
