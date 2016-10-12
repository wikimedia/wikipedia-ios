
#import "WMFFeedContentFetcher.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFFeedDayResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager *operationManager;
@end

@implementation WMFFeedContentFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFFeedDayResponse class] fromKeypath:nil];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}


- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date failure:(WMFErrorHandler)failure success:(void (^) (WMFFeedDayResponse* feedDay))success{
    NSParameterAssert(siteURL);
    NSParameterAssert(date);
    if(siteURL == nil || date  == nil){
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }
    
    NSString* datePath = [[NSDateFormatter wmf_yearMonthDayPathDateFormatter] stringFromDate:date];
    
    NSString *path = [NSString stringWithFormat:@"/api/rest_v1/feed/featured/%@", datePath];
    
    NSURL* url = [siteURL wmf_URLWithPath:path isMobile:NO];

    [self.operationManager GET:[url absoluteString]
                    parameters:nil
                      progress:NULL
                       success:^(NSURLSessionDataTask *operation, WMFFeedDayResponse *responseObject) {
                           if (![responseObject isKindOfClass:[WMFFeedDayResponse class]]) {
                               failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                                         userInfo:nil]);
                        
                           }else{
                               success(responseObject);
                           }
                       }
                       failure:^(NSURLSessionDataTask *operation, NSError *error) {
                           failure(error);
                       }];
}

@end

NS_ASSUME_NONNULL_END
