#import "WMFZeroMessageFetcher.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFZeroMessage.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFURLCacheStrings.h"

@interface WMFZeroMessageFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFZeroMessageFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationManager = [[AFHTTPSessionManager alloc] init];
        self.operationManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFZeroMessage class]
                                                          fromKeypath:nil];
    }
    return self;
}

- (AnyPromise *)fetchZeroMessageForSiteURL:(NSURL *)siteURL {
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
