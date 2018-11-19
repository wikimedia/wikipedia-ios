#import "WMFOnThisDayEventsFetcher.h"
#import "WMFFeedOnThisDayEvent.h"
#import <WMF/WMF-Swift.h>

@interface WMFOnThisDayEventsFetcher ()

@property (nonatomic, strong) WMFSession *session;

@end

@implementation WMFOnThisDayEventsFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.session = [WMFSession shared];
    }
    return self;
}

+ (NSSet<NSString *> *)supportedLanguages {
    static dispatch_once_t onceToken;
    static NSSet<NSString *> *supportedLanguages;
    dispatch_once(&onceToken, ^{
        supportedLanguages = [NSSet setWithObjects:@"en", @"de", @"sv", @"fr", @"es", @"ru", @"pt", @"ar", nil];
    });
    return supportedLanguages;
}

- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success {
    NSParameterAssert(siteURL);
    if (siteURL == nil || siteURL.wmf_language == nil || ![[WMFOnThisDayEventsFetcher supportedLanguages] containsObject:siteURL.wmf_language] || month < 1 || day < 1) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }

    NSURL *url = [siteURL wmf_URLWithPath:[NSString stringWithFormat:@"/api/rest_v1/feed/onthisday/events/%lu/%lu", (unsigned long)month, (unsigned long)day] isMobile:NO];

    [self.session getJSONDictionaryFromURL:url withQueryParameters:nil bodyParameters:nil ignoreCache:YES completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
            return;
        }
        
        if (response.statusCode == 304) {
            failure([NSError wmf_errorWithType:WMFErrorTypeNoNewData userInfo:nil]);
            return;
        }
        
        NSArray *eventJSONs = result[@"events"];
        if (![eventJSONs isKindOfClass:[NSArray class]]) {
            failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil]);
            return;
        }
        
        NSError *mantleError = nil;
        NSArray<WMFFeedOnThisDayEvent *> *events = [MTLJSONAdapter modelsOfClass:[WMFFeedOnThisDayEvent class] fromJSONArray:eventJSONs error:&mantleError];
        if (mantleError) {
            failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil]);
            return;
        }
        
        WMFFeedOnThisDayEvent *event = events.firstObject;
        if (![event isKindOfClass:[WMFFeedOnThisDayEvent class]]) {
            failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil]);
            return;
        }
        
        success(events);
    }];
}

@end
