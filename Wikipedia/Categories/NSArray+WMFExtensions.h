
#import <Foundation/Foundation.h>

@interface NSArray (WMFExtensions)

/// @return The object at `index` if it's within range of the receiver, otherwise `nil`.
- (id)wmf_safeObjectAtIndex:(NSUInteger)index;

/**
 *  Safely trim an array to a specified length.
 *  Will not throw an exception if
 *
 *  @param length The max length
 *
 *  @return The trimmed array
 */
- (instancetype)wmf_arrayByTrimmingToLength:(NSUInteger)length;

/// @return A reversed copy of the receiver.
- (instancetype)wmf_reverseArray;

@end
