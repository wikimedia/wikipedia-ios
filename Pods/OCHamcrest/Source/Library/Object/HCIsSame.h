//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsSame : HCBaseMatcher

+ (instancetype)isSameAs:(id)object;
- (instancetype)initSameAs:(id)object;

@end


FOUNDATION_EXPORT id HC_sameInstance(id object);

#ifdef HC_SHORTHAND
/*!
 * @brief sameInstance(anObject) -
 * Matches if evaluated object is the same instance as a given object.
 * @param anObject The object to compare against as the expected value.
 * @discussion This matcher compares the address of the evaluated object to determine if it is the
 * same object as <em>anObject</em>.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_sameInstance instead.
 */
#define sameInstance HC_sameInstance
#endif
