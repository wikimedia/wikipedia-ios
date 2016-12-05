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

        self.operationManager = manager;
        [self set304sEnabled:NO];

        AFHTTPSessionManager *unserializedOperationManager = [AFHTTPSessionManager wmf_createDefaultManager];
        self.unserializedOperationManager = unserializedOperationManager;
    }
    return self;
}

- (void)set304sEnabled:(BOOL)enabled {
    NSMutableIndexSet *set = [self.operationManager.responseSerializer.acceptableStatusCodes mutableCopy];
    if (enabled) {
        [set addIndex:304];
    } else {
        [set removeIndex:304];
    }
    self.operationManager.responseSerializer.acceptableStatusCodes = set;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success {
    [self fetchFeedContentForURL:siteURL date:date force:NO failure:failure success:success];
}

+ (NSURL *)feedContentURLForSiteURL:(NSURL *)siteURL onDate:(NSDate *)date {
    NSString *datePath = [[NSDateFormatter wmf_yearMonthDayPathDateFormatter] stringFromDate:date];

    NSString *path = [NSString stringWithFormat:@"/api/rest_v1/feed/featured/%@", datePath];

    return [siteURL wmf_URLWithPath:path isMobile:NO];
}

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success {
    NSParameterAssert(siteURL);
    NSParameterAssert(date);
    if (siteURL == nil || date == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }

    [self set304sEnabled:force];

    NSURL *url = [[self class] feedContentURLForSiteURL:siteURL onDate:date];

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
    NSParameterAssert(titleURL);

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

    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];

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

            NSDate *date = startDate;

            while ([date compare:endDate] == NSOrderedAscending) {
                if (results[date]) {
                    break;
                }
                results[date] = @(0);
                date = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:NSCalendarMatchStrictly];
            }

            success([results copy]);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
}

@end

NS_ASSUME_NONNULL_END
