//
//  WMFFeedItemExtractFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFENFeaturedTitleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFApiJsonResponseSerializer.h"
#import "MWKSite.h"

// Extract Response
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFENFeaturedTitleRequestSerializer : AFHTTPRequestSerializer
@end

@interface WMFENFeaturedTitleResponseSerializer : WMFApiJsonResponseSerializer

@end

@interface WMFENFeaturedTitleFetcher ()
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;
@end

@implementation WMFENFeaturedTitleFetcher

+ (AFHTTPRequestOperationManager*)operationManager {
    AFHTTPRequestOperationManager* operationManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    operationManager.requestSerializer = [WMFENFeaturedTitleRequestSerializer serializer];
    operationManager.responseSerializer = [WMFENFeaturedTitleResponseSerializer serializer];
    return operationManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationManager = [[self class] operationManager];
    }
    return self;
}

- (AnyPromise*)fetchFeedItemTitleForSite:(MWKSite*)site date:(nullable NSDate*)date {
    return [self.operationManager wmf_GETWithSite:site parameters:date operation:nil];
}

@end

@implementation WMFENFeaturedTitleRequestSerializer

+ (NSDateFormatter*)featuredArticleDateFormatter {
    static NSDateFormatter* feedItemDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        feedItemDateFormatter = [[NSDateFormatter alloc] init];
        feedItemDateFormatter.dateFormat = @"MMMM d, YYYY";
        // feed format uses US dates
        feedItemDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en-US"];
    });
    return feedItemDateFormatter;
}

+ (NSString*)normalizedTitleForDate:(nullable NSDate*)date {
    static NSString* tfaTitleTemplatePrefix = @"Template:TFA_title";
    if (!date) {
        // will automatically redirect to today's date
        return tfaTitleTemplatePrefix;
    }
    NSString* tfaTitle = [@[tfaTitleTemplatePrefix,
                            @"/",
                            [[self featuredArticleDateFormatter] stringFromDate:date]] componentsJoinedByString: @""];
    return [tfaTitle wmf_denormalizedPageTitle];;
}

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing _Nullable*)error {
    NSDate* date = parameters;
    NSParameterAssert(!date || [date isKindOfClass:[NSDate class]]);
    return [super requestBySerializingRequest:request withParameters:@{
                @"action": @"query",
                @"format": @"json",
                @"titles": [WMFENFeaturedTitleRequestSerializer normalizedTitleForDate:date],
                // extracts
                @"prop": @"extracts",
                @"exchars": @100,
                @"explaintext": @""
            } error:error];
}

@end

@implementation WMFENFeaturedTitleResponseSerializer

+ (nullable NSString*)titleFromFeedItemExtract:(nullable NSString*)extract {
    if ([extract hasSuffix:@"..."]) {
        return [extract wmf_safeSubstringToIndex:extract.length - 3];
    }
    return extract;

}

- (nullable id)responseObjectForResponse:(nullable NSURLResponse*)response
                                    data:(nullable NSData*)data
                                   error:(NSError* __autoreleasing _Nullable*)outError {
    id json = [super responseObjectForResponse:response data:data error:outError];
    if (!json) {
        return nil;
    }
    NSDictionary* feedItemPageObj = [[json[@"query"][@"pages"] allValues] firstObject];
    NSString* title               =
        [WMFENFeaturedTitleResponseSerializer titleFromFeedItemExtract:feedItemPageObj[@"extract"]];

    if (title.length == 0) {
        DDLogError(@"Empty extract for feed item request %@", response.URL);
        NSError* error = [NSError wmf_errorWithType:WMFErrorTypeStringLength userInfo:@{
                              NSURLErrorFailingURLErrorKey: response.URL
                          }];
        WMFSafeAssign(outError, error);
        return nil;
    }

    return title;
}

@end

NS_ASSUME_NONNULL_END
