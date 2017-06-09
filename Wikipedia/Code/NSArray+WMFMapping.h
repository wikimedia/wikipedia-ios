@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <__covariant ObjectType>
(WMFMapping)

    /**
 *  Map the array using the provided block.
 *  If nil is returned by the block an assertion will be thrown in DEBUG
 *  If not in debug, then [NSNull null] will be added to the array
 *
 *  @param block The block to map
 *
 *  @return The new array of mapped objects
 */
    - (NSArray *)wmf_strictMap : (id (^)(id obj))block;

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
- (NSArray *)wmf_mapAndRejectNil:(id _Nullable (^_Nonnull)(ObjectType _Nonnull obj))flatMap;

@end

NS_ASSUME_NONNULL_END
