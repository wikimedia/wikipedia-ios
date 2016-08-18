#import "NSTimeZone+WMFTestingUtils.h"

@implementation NSTimeZone (WMFTestingUtils)

+ (void)wmf_setDefaultTimeZoneForName:(NSString *)name {
    [self setDefaultTimeZone:[NSTimeZone timeZoneWithName:name]];
}

+ (void)wmf_resetDefaultTimeZone {
    [self setDefaultTimeZone:[NSTimeZone systemTimeZone]];
}

+ (void)wmf_forEachKnownTimeZoneAsDefault:(dispatch_block_t)block {
    [[NSTimeZone knownTimeZoneNames] bk_each:^(NSString *zoneName) {
        [NSTimeZone wmf_setDefaultTimeZoneForName:zoneName];
        block();
        [NSTimeZone wmf_resetDefaultTimeZone];
    }];
}

@end
