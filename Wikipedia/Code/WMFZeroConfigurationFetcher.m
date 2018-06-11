#import <WMF/WMFZeroConfigurationFetcher.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/WMFMantleJSONResponseSerializer.h>
#import <WMF/WMFZeroConfiguration.h>
#import <WMF/AFHTTPSessionManager+WMFCancelAll.h>
#import "WMFZeroConfigurationManager.h"
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WikipediaAppUtils.h>

@interface WMFZeroConfigurationFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFZeroConfigurationFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationManager = [[AFHTTPSessionManager alloc] init];
        self.operationManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFZeroConfiguration class] fromKeypath:nil emptyValueForJSONKeypathAllowed:NO];
    }
    return self;
}

- (void)dealloc {
    [self.operationManager invalidateSessionCancelingTasks:YES];
}

- (void)fetchZeroConfigurationForSiteURL:(NSURL *)siteURL failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"action": @"zeroconfig",
        @"type": @"message",
        @"agent": [WikipediaAppUtils versionedUserAgent]
    }];
    [self.operationManager GET:[[NSURL wmf_mobileAPIURLForURL:siteURL] absoluteString]
        parameters:params
        progress:NULL
        success:^(NSURLSessionDataTask *_Nonnull _, id _Nonnull responseObject) {
            success(responseObject);
        }
        failure:^(NSURLSessionDataTask *_Nullable _, NSError *_Nonnull error) {
            failure(error);
        }];
}

- (void)cancelAllFetches {
    [self.operationManager wmf_cancelAllTasks];
}

@end
