//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCIsIn : HCBaseMatcher

+ (instancetype)isInCollection:(id)collection;
- (instancetype)initWithCollection:(id)collection;

@end


FOUNDATION_EXPORT id HC_isIn(id aCollection);

#ifdef HC_SHORTHAND
/*!
 * @brief isIn(aCollection) -
 * Matches if evaluated object is present in a given collection.
 * @param aCollection The collection to search.
 * @discussion This matcher invokes <code>-containsObject:</code> on <em>aCollection</em> to
 * determine if the evaluated object is an element of the collection.
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_isIn instead.
 */
#define isIn HC_isIn
#endif
