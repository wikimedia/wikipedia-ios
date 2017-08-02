@import Foundation;

@interface NSTimeZone (WMFTestingUtils)

+ (void)wmf_setDefaultTimeZoneForName:(NSString *)name;

/**
 *  Resets the @c defaultTimeZone to its default value, the current @c systemTimeZone.
 */
+ (void)wmf_resetDefaultTimeZone;

+ (void)wmf_forEachKnownTimeZoneAsDefault:(dispatch_block_t)block;

@end
