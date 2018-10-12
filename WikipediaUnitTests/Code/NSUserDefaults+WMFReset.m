#import "NSUserDefaults+WMFReset.h"

@implementation NSUserDefaults (WMFReset)

- (void)wmf_resetToDefaultValues {
    [self removePersistentDomainForName:WMFApplicationGroupIdentifier];
}

@end
