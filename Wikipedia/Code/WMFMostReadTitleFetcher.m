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

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFArrayOfNumbersHandler)success {
    NSString *title = [titleURL.wmf_titleWithUnderScores wmf_UTF8StringWithPercentEscapes];
    NSString *language = titleURL.wmf_language;
    NSString *domain = titleURL.wmf_domain;

    NSParameterAssert(title);
    NSParameterAssert(language);
    NSParameterAssert(domain);
    NSParameterAssert(startDate);
    NSParameterAssert(endDate);
    if (startDate == nil || endDate == nil || title == nil || language == nil || domain == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }

    NSString *startDateString = [[NSDateFormatter wmf_englishUTCNonDelimitedYearMonthDayFormatter] stringFromDate:startDate];
    NSString *endDateString = [[NSDateFormatter wmf_englishUTCNonDelimitedYearMonthDayFormatter] stringFromDate:endDate];

    if (startDateString == nil || endDateString == nil) {
        DDLogError(@"Failed to format pageviews date URL component for dates: %@ %@", startDate, endDate);
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:@{ WMFFailingRequestParametersUserInfoKey: @{@"start": startDate, @"end": endDate} }];
        failure(error);
        return;
    }

    NSString *path = [NSString stringWithFormat:@"/metrics/pageviews/per-article/%@.%@/all-access/user/%@/daily/%@/%@",
                                                language, domain, title, startDateString, endDateString];

    NSString *requestURLString = [WMFWikimediaRestAPIURLStringWithVersion(1) stringByAppendingString:path];

    [self.operationManager GET:requestURLString
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, NSDictionary *responseObject) {
            NSArray *items = responseObject[@"items"];
            if (![items isKindOfClass:[NSArray class]]) {
                failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                          userInfo:nil]);
                return;
            }

            NSMutableArray *results = [NSMutableArray arrayWithCapacity:[items count]];
            for (id item in items) {
                if ([item isKindOfClass:[NSDictionary class]] && [item[@"views"] isKindOfClass:[NSNumber class]]) {
                    [results addObject:item[@"views"]];
                }
            }

            success([results copy]);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
}

@end

NS_ASSUME_NONNULL_END
