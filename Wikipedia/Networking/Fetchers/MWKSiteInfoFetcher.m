//
//  MWKSiteInfoFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteInfoFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+UniqueRequests.h"
#import "WMFNetworkUtilities.h"
#import "WMFApiJsonResponseSerializer.h"
#import "MWKSite.h"
#import "MWKSiteInfo.h"

@interface MWKSiteInfoFetcher ()
@end

@implementation MWKSiteInfoFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestManager                    = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        self.requestManager.responseSerializer = [WMFApiJsonResponseSerializer serializer];
    }
    return self;
}

- (void)fetchInfoForSite:(MWKSite*)site success:(void (^)(MWKSiteInfo*))success failure:(void (^)(NSError*))error {
    return [self fetchInfoForSite:site success:success failure:error callbackQueue:dispatch_get_main_queue()];
}

- (void)fetchInfoForSite:(MWKSite*)site
                 success:(void (^)(MWKSiteInfo*))success
                 failure:(void (^)(NSError*))failure
           callbackQueue:(dispatch_queue_t)queue {
    NSParameterAssert(site);
    NSDictionary* params = @{
        @"action": @"query",
        @"meta": @"siteinfo",
        @"format": @"json",
        @"siprop": @"general"
    };
    [self.requestManager wmf_idempotentGET:site.apiEndpoint.absoluteString
                                parameters:params
                                   success:^(AFHTTPRequestOperation* op, NSDictionary* json) {
        NSDictionary* generalProps = [json valueForKeyPath:@"query.general"];
        MWKSiteInfo* info = [[MWKSiteInfo alloc] initWithSite:site mainPageTitleText:generalProps[@"mainpage"]];
        dispatch_async(queue, ^{
            [self.fetchFinishedDelegate fetchFinished:self
                                          fetchedData:info
                                               status:FETCH_FINAL_STATUS_SUCCEEDED
                                                error:nil];
            success(info);
        });
    }
                                   failure:^(AFHTTPRequestOperation* op, NSError* error) {
        dispatch_async(queue, ^{
            [self.fetchFinishedDelegate fetchFinished:self
                                          fetchedData:nil
                                               status:error.wmf_fetchStatus
                                                error:nil];
            failure(error);
        });
    }];
}

@end
