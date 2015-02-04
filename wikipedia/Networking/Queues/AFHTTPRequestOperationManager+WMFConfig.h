//
//  AFHTTPRequestOperationManager+WMFConfig.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface AFHTTPRequestOperationManager (WMFConfig)

/**
 * Create a new instance configured with WMF application settings:
 * - proprietary request headers
 * - JSON response serializer
 */
+ (instancetype)wmf_createDefaultManager;

/// Configure the receiver to use WMF proprietary request headers.
- (void)wmf_applyAppRequestHeaders;

@end
