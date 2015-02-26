
#import <Foundation/Foundation.h>

@interface NSArray (WMFExtensions)

/**
 *  Safely trim an array to a specified length.
 *  Will not throw an exception if
 *
 *  @param length The max length
 *
 *  @return The trimmed array
 */
- (NSArray*)wmf_arrayByTrimmingToLength:(NSUInteger)length;

@end
