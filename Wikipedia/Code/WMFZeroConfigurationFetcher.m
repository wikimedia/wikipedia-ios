#import "WMFZeroConfigurationFetcher.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFZeroConfiguration.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFURLCacheStrings.h"

@interface WMFZeroConfigurationFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFZeroConfigurationFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationManager = [[AFHTTPSessionManager alloc] init];
        self.operationManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFZeroConfiguration class]
                                                          fromKeypath:nil];
    }
    return self;
}

- (AnyPromise *)fetchZeroConfigurationForSiteURL:(NSURL *)siteURL {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"action": @"zeroconfig",
            @"type": @"message",
            @"agent": [WikipediaAppUtils versionedUserAgent]
        }];
        //        if ([FBTweak wmf_shouldMockWikipediaZeroHeaders]) {
        //            params[WMFURLCacheXCarrier] = @"TEST";
        //        }
        [self.operationManager GET:[[NSURL wmf_mobileAPIURLForURL:siteURL] absoluteString]
            parameters:params
            progress:NULL
            success:^(NSURLSessionDataTask *_Nonnull _, id _Nonnull responseObject) {
                resolve(responseObject);
            }
            failure:^(NSURLSessionDataTask *_Nullable _, NSError *_Nonnull error) {
                resolve(error);
            }];
    }];
}

- (void)cancelAllFetches {
    [self.operationManager wmf_cancelAllTasks];
}

@end
