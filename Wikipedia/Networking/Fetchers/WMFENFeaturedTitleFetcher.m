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
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNetworkUtilities.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"

// Extract Response
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFENFeaturedTitleRequestSerializer : AFHTTPRequestSerializer
@end

@interface WMFENFeaturedTitleResponseSerializer : WMFApiJsonResponseSerializer
@end

@interface WMFTitlePreviewRequestSerializer : AFHTTPRequestSerializer
@end

@interface WMFENFeaturedTitleFetcher ()
@property (nonatomic, strong) AFHTTPRequestOperationManager* featuredTitleOperationManager;
@property (nonatomic, strong) AFHTTPRequestOperationManager* titlePreviewOperationManager;
@end

@implementation WMFENFeaturedTitleFetcher

+ (AFHTTPRequestOperationManager*)featuredTitleOperationManager {
    AFHTTPRequestOperationManager* featuredTitleOperationManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    featuredTitleOperationManager.requestSerializer = [WMFENFeaturedTitleRequestSerializer serializer];
    featuredTitleOperationManager.responseSerializer = [WMFENFeaturedTitleResponseSerializer serializer];
    return featuredTitleOperationManager;
}

+ (AFHTTPRequestOperationManager*)titlePreviewOperationManager {
    AFHTTPRequestOperationManager* titlePreviewOperationManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    titlePreviewOperationManager.requestSerializer = [WMFTitlePreviewRequestSerializer serializer];
    titlePreviewOperationManager.responseSerializer =
        [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class] fromKeypath:@"query.pages"];
    return titlePreviewOperationManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.featuredTitleOperationManager = [WMFENFeaturedTitleFetcher featuredTitleOperationManager];
        self.titlePreviewOperationManager = [WMFENFeaturedTitleFetcher titlePreviewOperationManager];
    }
    return self;
}

- (AnyPromise*)fetchFeedItemTitleForSite:(MWKSite*)site date:(nullable NSDate*)date {
    @weakify(self);
    return [self.featuredTitleOperationManager wmf_GETWithSite:site parameters:date operation:nil]
    .thenInBackground(^(NSString* title) {
        @strongify(self);
        if (!self) {
            return [AnyPromise promiseWithValue:[NSError cancelledError]];
        }
        return [self.titlePreviewOperationManager wmf_GETWithSite:site parameters:title operation:nil];
    });
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

@implementation WMFTitlePreviewRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing _Nullable*)error {
    NSString* title = parameters;
    NSParameterAssert([title isKindOfClass:[NSString class]] && title.length);
    return [super requestBySerializingRequest:request withParameters:@{
                @"continue": @"",
                @"format": @"json",
                @"action": @"query",
                @"titles": title,
                @"prop": WMFJoinedPropertyParameters(@[@"extracts", @"pageterms", @"pageimages"]),
                // extracts
                @"exintro": @YES,
                @"exchars": @300,
                @"explaintext": @"",
                // pageterms
                @"wbptterms": @"description",
                // pageimage
                @"piprop": @"thumbnail",
                @"pithumbsize": @(LEAD_IMAGE_WIDTH),
            } error:error];
}

@end

NS_ASSUME_NONNULL_END
