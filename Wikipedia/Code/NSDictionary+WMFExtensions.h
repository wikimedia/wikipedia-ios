
#import <Foundation/Foundation.h>

@interface NSDictionary (WMFExtensions)

/**
 *  Used to find dictionaries that contain Nulls
 *
 *  @return YES if any objects are [NSNUll null], otherwise NO
 */
- (BOOL)containsNullObjects;

@end
