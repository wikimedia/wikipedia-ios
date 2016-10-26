#import "PiwikTracker+WMFExtensions.h"
#import "NSBundle+WMFInfoUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (WMFAnalyticsContentTypeProviding)

- (NSString*)analyticsContentType{
    return self;
}

@end

@implementation PiwikTracker (WMFExtensions)

+ (void)wmf_start {
#ifndef DEBUG
    static NSTimeInterval const WMFDispatchInterval = 60;
    NSString *piwikHostURLString = @"https://piwik.wikimedia.org/";
    NSString *appID = @"3";
    [PiwikTracker sharedInstanceWithSiteID:appID baseURL:[NSURL URLWithString:piwikHostURLString]];
    [[PiwikTracker wmf_configuredInstance] setDispatchInterval:WMFDispatchInterval];
#endif
}

+ (nullable instancetype)wmf_configuredInstance {
#ifndef DEBUG
    return [self sharedInstance];
#else
    return nil;
#endif
}

- (void)wmf_logView:(id<WMFAnalyticsViewNameProviding>)view {
    NSParameterAssert([view analyticsName]);
#ifndef DEBUG
    [self sendView:[view analyticsName]];
#endif
}

- (void)wmf_sendEventWithCategory:(NSString *)category action:(NSString *)action name:(NSString *)name value:(nullable NSNumber *)value {
#ifndef DEBUG
    [self sendEventWithCategory:category
                         action:action
                           name:name
                          value:value];
#endif
}

- (void)wmf_logActionPreviewInContext:(id<WMFAnalyticsContextProviding>)context
                          contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Preview"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionTapThroughInContext:(id<WMFAnalyticsContextProviding>)context
                             contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Tap Through"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionSaveInContext:(id<WMFAnalyticsContextProviding>)context
                       contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Save"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionUnsaveInContext:(id<WMFAnalyticsContextProviding>)context
                         contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Unsave"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionImpressionInContext:(id<WMFAnalyticsContextProviding>)context
                             contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Impression"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionTapThroughMoreInContext:(id<WMFAnalyticsContextProviding>)context
                                 contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Tap Through More"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionSwitchLanguageInContext:(id<WMFAnalyticsContextProviding>)context
                                 contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Switch Language"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionEnableInContext:(id<WMFAnalyticsContextProviding>)context
                                 contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Enable"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionDisableInContext:(id<WMFAnalyticsContextProviding>)context
                         contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Disable"
                               name:[contentType analyticsContentType]
                              value:nil];
}

@end

NS_ASSUME_NONNULL_END
