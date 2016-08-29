#import "WMFMostReadTitleFetcher.h"
#import <Mantle/MTLJSONAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadTitleFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager *operationManager;
@end

@implementation WMFMostReadTitleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise *)fetchMostReadTitlesForSiteURL:(NSURL *)siteURL date:(NSDate *)date {
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        return [AnyPromise promiseWithValue:error];
    }

    NSParameterAssert(date);
    if (date == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        return [AnyPromise promiseWithValue:error];
    }

    NSString *dateString = [[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date];
    if (dateString == nil) {
        DDLogError(@"Failed to format pageviews date URL component for date: %@", date);
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:@{WMFFailingRequestParametersUserInfoKey: date}];
        return [AnyPromise promiseWithValue:error];
    }

    NSString *path = [NSString stringWithFormat:@"/metrics/pageviews/top/%@.%@/all-access/%@",
                                                siteURL.wmf_language, siteURL.wmf_domain, dateString];

    NSString *requestURLString = [WMFWikimediaRestAPIURLStringWithVersion(1) stringByAppendingPathComponent:path];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
               [self.operationManager GET:requestURLString
                   parameters:nil
                   progress:NULL
                   success:^(NSURLSessionDataTask *operation, NSDictionary *responseObject) {
                       NSError *parseError;
                       WMFMostReadTitlesResponse *titlesResponse = [MTLJSONAdapter modelOfClass:[WMFMostReadTitlesResponse class]
                                                                             fromJSONDictionary:responseObject
                                                                                          error:&parseError];
                       WMFMostReadTitlesResponseItem *firstItem = titlesResponse.items.firstObject;

                       NSCAssert([[NSCalendar wmf_utcGregorianCalendar] compareDate:date
                                                                             toDate:firstItem.date
                                                                  toUnitGranularity:NSCalendarUnitDay] == NSOrderedSame,
                                 @"Date for most-read articles (%@) doesn't match original fetch date: %@",
                                 firstItem.date, date);

                       resolve(firstItem ?: parseError);
                   }
                   failure:^(NSURLSessionDataTask *operation, NSError *error) {
                       resolve(error);
                   }];
           }]
        .finally(^{
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
        });
}

@end

NS_ASSUME_NONNULL_END
