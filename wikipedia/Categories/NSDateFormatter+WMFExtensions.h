
#import <Foundation/Foundation.h>

@interface NSDateFormatter (WMFExtensions)

/**
 *  Standard formatter. Cached for performance
 *
 *  @return The formatter
 */
+ (NSDateFormatter*)wmf_iso8601Formatter;

@end
