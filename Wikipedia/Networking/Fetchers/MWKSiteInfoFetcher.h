//
//  MWKSiteInfoFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FetcherBase.h"

@class MWKSiteInfo;
@class MWKSite;
@class AFHTTPRequestOperationManager;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSiteInfoFetcher : FetcherBase
@property (strong, nonatomic) AFHTTPRequestOperationManager* requestManager;

/// Attempt to fetch siteinfo for the given site.
- (void)fetchInfoForSite:(MWKSite*)site
                 success:(void (^)(MWKSiteInfo*))success
                 failure:(void (^)(NSError*))failure;

- (void)fetchInfoForSite:(MWKSite*)site
                 success:(void (^)(MWKSiteInfo*))success
                 failure:(void (^)(NSError*))failure
           callbackQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
