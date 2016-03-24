//
//  WMFZeroMessageFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFZeroMessageFetcher.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFZeroMessage.h"
#import "WikipediaAppUtils.h"
#import "FBTweak+WikipediaZero.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"


@interface WMFZeroMessageFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager* operationManager;

@end

@implementation WMFZeroMessageFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationManager                    = [[AFHTTPSessionManager alloc] init];
        self.operationManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFZeroMessage class]
                                                          fromKeypath:nil];
    }
    return self;
}

- (AnyPromise*)fetchZeroMessageForSite:(MWKSite*)site {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:@{
                                           @"action": @"zeroconfig",
                                           @"type": @"message",
                                           @"agent": [WikipediaAppUtils versionedUserAgent]
                                       }];
        if ([FBTweak wmf_shouldMockWikipediaZeroHeaders]) {
            params[@"X-CS"] = @"TEST";
        }
        [self.operationManager GET:[[site mobileApiEndpoint] absoluteString]
                        parameters:params
                          progress:NULL
                           success:^(NSURLSessionDataTask* _Nonnull _, id _Nonnull responseObject) {
            resolve(responseObject);
        } failure:^(NSURLSessionDataTask* _Nullable _, NSError* _Nonnull error) {
            resolve(error);
        }];
    }];
}

- (void)cancelAllFetches {
    [self.operationManager wmf_cancelAllTasks];
}

@end
