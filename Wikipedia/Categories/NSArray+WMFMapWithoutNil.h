//
//  NSArray+WMFMapWithoutNil.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/13/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant ObjectType> (WMFMapWithoutNil)

/**
 *  Transform the elements in the receiver, returning @c nil for those that should be excluded.
 *
 *  Reduces a common pattern of mapping/filtering in one step.
 *
 *  @param flatMap Block which takes a single parameter of the type of elements in the receiver, and returns
 *         another object or @c nil if the object should be excluded from the result.
 *
 *  @return A new array with the objects transformed by @c flatMap, excluding the @c nil results.
 */
- (NSArray*)wmf_mapAndRejectNil:(id _Nullable (^ _Nonnull)(__kindof ObjectType _Nonnull obj))flatMap;

@end

NS_ASSUME_NONNULL_END
