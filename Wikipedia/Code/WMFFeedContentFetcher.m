#import "WMFFeedContentFetcher.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFFeedDayResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager *operationManager;
@property (nonatomic, strong) AFHTTPSessionManager *unserializedOperationManager;
@end

@implementation WMFFeedContentFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFFeedDayResponse class] fromKeypath:nil];
        NSMutableIndexSet* set = [manager.responseSerializer.acceptableStatusCodes mutableCopy];
        [set removeIndex:304];
        manager.responseSerializer.acceptableStatusCodes = set;

        self.operationManager = manager;

        AFHTTPSessionManager *unserializedOperationManager = [AFHTTPSessionManager wmf_createDefaultManager];
        self.unserializedOperationManager = unserializedOperationManager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success {
    NSParameterAssert(siteURL);
    NSParameterAssert(date);
    if (siteURL == nil || date == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }

    NSString *datePath = [[NSDateFormatter wmf_yearMonthDayPathDateFormatter] stringFromDate:date];

    NSString *path = [NSString stringWithFormat:@"/api/rest_v1/feed/featured/%@", datePath];

    NSURL *url = [siteURL wmf_URLWithPath:path isMobile:NO];

    [self.operationManager GET:[url absoluteString]
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, WMFFeedDayResponse *responseObject) {
            if (![responseObject isKindOfClass:[WMFFeedDayResponse class]]) {
                failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                          userInfo:nil]);

            } else {
                success(responseObject);
            }
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
}

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFPageViewsHandler)success {
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

    [self.unserializedOperationManager GET:requestURLString
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, NSDictionary *responseObject) {
            NSArray *items = responseObject[@"items"];
            if (![items isKindOfClass:[NSArray class]]) {
                failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                          userInfo:nil]);
                return;
            }

            NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:[items count]];
            for (id item in items) {
                if ([item isKindOfClass:[NSDictionary class]] && [item[@"views"] isKindOfClass:[NSNumber class]] && [item[@"timestamp"] isKindOfClass:[NSString class]]) {
                    NSDate *date = [[NSDateFormatter wmf_englishUTCNonDelimitedYearMonthDayHourFormatter] dateFromString:item[@"timestamp"]];
                    results[date] = item[@"views"];
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
