
#import <Foundation/Foundation.h>

@interface NSArray (WMFMapping)

/**
 *  Map the array using the provided block.
 *  If nil is returned by the block an assertion will be thrown in DEBUG
 *  If not in debug, then [NSNull null] will be added to the array
 *
 *  @param block The block to map
 *
 *  @return The new array of mapped objects
 */
- (NSArray*)wmf_strictMap:(id (^)(id obj))block;

/**
 *  Map the array using the provided block.
 *  If nil is returned by the block then the object will be skipped.
 *  This may result in the array being shorter than the original.
 *
 *  @param block The block to map
 *
 *  @return The new array of mapped objects
 */
- (NSArray*)wmf_mapRemovingNilElements:(id (^)(id obj))block;

@end
