//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt
//  Contribution by Todd Farrell

#import <OCHamcrest/HCBaseMatcher.h>


@interface HCConformsToProtocol : HCBaseMatcher

+ (instancetype)conformsTo:(Protocol *)protocol;
- (instancetype)initWithProtocol:(Protocol *)protocol;

@end


FOUNDATION_EXPORT id HC_conformsTo(Protocol *aProtocol);

#ifdef HC_SHORTHAND
/*!
 * @brief conformsTo(aProtocol) -
 * Matches if object conforms to a given protocol.
 * @param aProtocol The protocol to compare against as the expected protocol.
 * @discussion This matcher checks whether the evaluated object conforms to <em>aProtocol</em>.
 *
 * Example:
 * <ul>
 *   <li><code>conformsTo(\@protocol(NSObject))</code></li>
 * </ul>
 *
 * @attribute Name Clash
 * In the event of a name clash, don't <code>#define HC_SHORTHAND</code> and use the synonym
 * HC_conformsTo instead.
 */
#define conformsTo HC_conformsTo
#endif
