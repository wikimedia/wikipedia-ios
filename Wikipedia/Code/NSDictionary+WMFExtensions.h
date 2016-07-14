
#import <Foundation/Foundation.h>

@interface NSDictionary (WMFExtensions)

/**
 *  Used to find dictionaries that contain Nulls
 *
 *  @return YES if any objects are [NSNull null], otherwise NO
 */
- (BOOL)wmf_containsNullObjects;


/**
 *  Used to find dictionaries that contain Nulls or contain sub-dictionaries or arrays that contain Nulls
 *
 *  @return YES if any objects or sub-collection objects are [NSNull null], otherwise NO
 */
- (BOOL)wmf_recursivelyContainsNullObjects;


/**
 *  Remove Nulls from a dictionary before returning it
 *
 *  @return A dictionary without any [NSNull nulls]
 */
- (NSDictionary*)wmf_dictionaryByRemovingNullObjects;



@end
