//
//  WMFAuthManagerInfoFetcher.m
//  Wikipedia
//
//  Created by Corey Floyd on 6/8/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFAuthManagerInfoFetcher.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFAuthManagerInfo.h"
#import "MWKSite.h"


@interface WMFAuthManagerInfoFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager* operationManager;
@end

@implementation WMFAuthManagerInfoFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager* manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFAuthManagerInfo class] fromKeypath:@"query"];
        self.operationManager      = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchAuthManagerLoginAvailableForSite:(MWKSite*)site {
    return [self fetchAuthManagerAvailableForSite:site type:@"login"];
}

- (AnyPromise*)fetchAuthManagerCreationAvailableForSite:(MWKSite*)site {
    return [self fetchAuthManagerAvailableForSite:site type:@"create"];
}

- (AnyPromise*)fetchAuthManagerAvailableForSite:(MWKSite*)site type:(NSString*)type {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSDictionary* params = @{
            @"action": @"query",
            @"meta": @"authmanagerinfo",
            @"format": @"json",
            @"amirequestsfor": type
        };

        [self.operationManager wmf_GETWithSite:site parameters:params]
        .then(^(id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(responseObject);
        }).catch(^(NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        });
    }];
}

@end
