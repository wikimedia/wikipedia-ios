//
//  NSBundle+WMFInfoUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSBundle+WMFInfoUtils.h"

@implementation NSBundle (WMFInfoUtils)

- (NSString*)wmf_bundleIdentifier {
    return [self objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (BOOL)wmf_isAppStoreBundleIdentifier {
    return [[self wmf_bundleIdentifier] hasSuffix:@"wikipedia"];
}

- (NSString*)wmf_bundleVersion {
    return [self objectForInfoDictionaryKey:@"CFBundleVersion"] ? : @"";
}

- (NSString*)wmf_shortVersionString {
    return [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ? : @"";
}

- (NSString*)wmf_releaseVersion {
    return [self wmf_shortVersionString];
}

- (NSString*)wmf_debugVersion {
    return [[self wmf_releaseVersion] stringByAppendingFormat:@".%@", [self wmf_bundleVersion] ? : @"0"];
}

- (NSString*)wmf_versionForCurrentBundleIdentifier {
    return [self wmf_isAppStoreBundleIdentifier] ? [self wmf_releaseVersion] : [self wmf_debugVersion];
}

@end
