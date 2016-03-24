//
//  WMFMostReadTitleFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/11/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadTitleFetcher.h"

#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFNetworkUtilities.h"
#import "MWKSite.h"
#import "NSDateFormatter+WMFExtensions.h"
#import <Mantle/MTLJSONAdapter.h>
#import "WMFMostReadTitlesResponse.h"
#import "NSCalendar+WMFCommonCalendars.h"
#import "NSError+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadTitleFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager* operationManager;
@end

@implementation WMFMostReadTitleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager* manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchMostReadTitlesForSite:(MWKSite*)site date:(NSDate*)date {
    NSParameterAssert(site);
    NSParameterAssert(date);
    NSString* dateString = [[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date];
    if (!date) {
        DDLogError(@"Failed to format pageviews date URL component for date: %@", date);
        NSError* error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:@{WMFFailingRequestParametersUserInfoKey: date}];
        return [AnyPromise promiseWithValue:error];
    }

    NSString* path = [NSString stringWithFormat:@"/metrics/pageviews/top/%@.%@/all-access/%@",
                      site.language, site.domain, dateString];

    NSString* requestURLString = [WMFWikimediaRestAPIURLStringWithVersion(1) stringByAppendingPathComponent:path];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.operationManager GET:requestURLString
                        parameters:nil
                          progress:NULL
                           success:^(NSURLSessionDataTask* operation, NSDictionary* responseObject) {
            NSError* parseError;
            WMFMostReadTitlesResponse* titlesResponse = [MTLJSONAdapter modelOfClass:[WMFMostReadTitlesResponse class]
                                                                  fromJSONDictionary:responseObject
                                                                               error:&parseError];
            WMFMostReadTitlesResponseItem* firstItem = titlesResponse.items.firstObject;

            NSCAssert([[NSCalendar wmf_utcGregorianCalendar] compareDate:date
                                                                  toDate:firstItem.date
                                                       toUnitGranularity:NSCalendarUnitDay] == NSOrderedSame,
                      @"Date for most-read articles (%@) doesn't match original fetch date: %@",
                      firstItem.date, date);

            resolve(firstItem ? : parseError);
        }
                           failure:^(NSURLSessionDataTask* operation, NSError* error) {
            resolve(error);
        }];
    }].finally(^{
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
    });
}

@end

NS_ASSUME_NONNULL_END
