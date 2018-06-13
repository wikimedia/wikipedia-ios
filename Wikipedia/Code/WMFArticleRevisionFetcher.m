#import "WMFArticleRevisionFetcher.h"
@import WMF.AFHTTPSessionManager_WMFConfig;
@import WMF.AFHTTPSessionManager_WMFDesktopRetry;
@import WMF.WMFMantleJSONResponseSerializer;
@import WMF.WMFNetworkUtilities;
@import WMF.NSURL_WMFLinkParsing;
#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"

@interface WMFArticleRevisionFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
@end

@implementation WMFArticleRevisionFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestManager = [AFHTTPSessionManager wmf_createDefaultManager];
        self.requestManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForArrayOf:[WMFRevisionQueryResults class] fromKeypath:@"query.pages" emptyValueForJSONKeypathAllowed:NO];
    }
    return self;
}

- (void)dealloc {
    [self.requestManager invalidateSessionCancelingTasks:YES];
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    self.requestManager.requestSerializer.timeoutInterval = timeoutInterval;
}

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                     endingWithRevision:(NSUInteger)revisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success {
    return [self.requestManager wmf_GETAndRetryWithURL:articleURL
        parameters:@{
            @"format": @"json",
            @"continue": @"",
            @"formatversion": @2,
            @"action": @"query",
            @"prop": @"revisions",
            @"redirects": @1,
            @"titles": articleURL.wmf_title,
            @"rvlimit": @(numberOfResults),
            @"rvendid": @(revisionId),
            @"rvprop": WMFJoinedPropertyParameters(@[@"ids", @"size", @"flags"]) //,
            //@"pilicense": @"any"
        }
        retry:^(NSURLSessionDataTask *retryOperation, NSError *error) {

        }
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            success([responseObject firstObject]);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
}

@end
