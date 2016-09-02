#import "NSUserDefaults+WMFReset.h"

@implementation NSUserDefaults (WMFReset)

- (void)wmf_resetToDefaultValues {
    [self removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [self synchronize];
}

@end
