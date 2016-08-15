//
//  NSProcessInfo+WMFOperatingSystemVersionChecks.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSProcessInfo (WMFOperatingSystemVersionChecks)

/**
 *  @return Whether or not the current OS version is less than 9.0.0.
 *
 *  @note This method is preferred to the parameterized ones, since it will automatically mark code as deprecated once
 *        the deployment target is raised.
 */
- (BOOL)wmf_isOperatingSystemVersionLessThan9_0_0 WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9;

- (BOOL)wmf_isOperatingSystemMajorVersionAtLeast:(NSInteger)version;

- (BOOL)wmf_isOperatingSystemMajorVersionLessThan:(NSInteger)version;

@end
