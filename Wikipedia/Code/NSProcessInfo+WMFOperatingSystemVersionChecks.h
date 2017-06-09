@import Foundation;

@interface NSProcessInfo (WMFOperatingSystemVersionChecks)

/**
 *  @return Whether or not the current OS version is less than 9.0.0.
 *
 *  @note This method is preferred to the parameterized ones, since it will automatically mark code as deprecated once
 *        the deployment target is raised.
 */
- (BOOL)wmf_isOperatingSystemMajorVersionAtLeast:(NSInteger)version;

- (BOOL)wmf_isOperatingSystemMajorVersionLessThan:(NSInteger)version;

@end
