#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

@implementation NSProcessInfo (WMFOperatingSystemVersionChecks)

- (BOOL)wmf_isOperatingSystemVersionLessThan9_0_0 {
    return [self wmf_isOperatingSystemMajorVersionLessThan:9];
}

- (BOOL)wmf_isOperatingSystemMajorVersionAtLeast:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion >= version;
}

- (BOOL)wmf_isOperatingSystemMajorVersionLessThan:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion < version;
}

@end
