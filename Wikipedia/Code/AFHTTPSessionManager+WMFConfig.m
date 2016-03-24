//
//  AFHTTPSessionManager+WMFConfig.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AFHTTPSessionManager+WMFConfig.h"
#import "SessionSingleton.h"
#import "ReadingActionFunnel.h"
#import "WikipediaAppUtils.h"

@implementation AFHTTPSessionManager (WMFConfig)

+ (instancetype)wmf_createDefaultManager {
    AFHTTPSessionManager* manager = [self manager];
    [manager wmf_applyAppRequestHeaders];
    return manager;
}

- (void)wmf_applyAppRequestHeaders {
    NSParameterAssert(self.requestSerializer);
    [self.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self.requestSerializer setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // Add the app install ID to the header, but only if the user has not opted out of logging
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        ReadingActionFunnel* funnel = [[ReadingActionFunnel alloc] init];
        [self.requestSerializer setValue:funnel.appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
    }
}

@end
