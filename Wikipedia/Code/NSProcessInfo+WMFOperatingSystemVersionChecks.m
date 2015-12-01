//
//  NSProcessInfo+WMFOperatingSystemVersionChecks.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

@implementation NSProcessInfo (WMFOperatingSystemVersionChecks)

- (BOOL)wmf_isOperatingSystemVersionLessThan9_0_0 {
    return [self wmf_isOperationSystemMajorVersionLessThan:9];
}

- (BOOL)wmf_isOperationSystemMajorVersionAtLeast:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion >= version;
}

- (BOOL)wmf_isOperationSystemMajorVersionLessThan:(NSInteger)version {
    return self.operatingSystemVersion.majorVersion < version;
}

@end
