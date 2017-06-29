#import <WMF/NSProcessInfo+WMFOperatingSystemVersionChecks.h>

@implementation NSProcessInfo (WMFOperatingSystemVersionChecks)

- (BOOL)wmf_isOperatingSystemMajorVersionAtLeast:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion >= version;
}

- (BOOL)wmf_isOperatingSystemMajorVersionLessThan:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion < version;
}

@end
