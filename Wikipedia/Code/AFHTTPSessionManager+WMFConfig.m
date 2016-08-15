//
//  AFHTTPSessionManager+WMFConfig.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"

@implementation AFHTTPSessionManager (WMFConfig)

+ (instancetype)wmf_createDefaultManager {
    AFHTTPSessionManager *manager = [self manager];
    [manager.requestSerializer wmf_applyAppRequestHeaders];
    return manager;
}

@end
