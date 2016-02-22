
#import "PiwikTracker+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFPiwikServerURL = @"http://piwik.wmflabs.org/piwik/";
static NSString* const WMFPiwikSiteID    = @"4";

@implementation PiwikTracker (WMFExtensions)

+ (void)wmf_start {
#ifdef PIWIK_ENABLED
    [PiwikTracker sharedInstanceWithSiteID:WMFPiwikSiteID baseURL:[NSURL URLWithString:WMFPiwikServerURL]];
    [[PiwikTracker sharedInstance] setDispatchInterval:60];
#endif
}

- (void)wmf_logView:(id<WMFAnalyticsViewNameProviding>)view {
    NSParameterAssert([view analyticsName]);
#ifdef PIWIK_ENABLED
    [self sendView:[view analyticsName]];
#endif
}

- (void)wmf_sendEventWithCategory:(NSString*)category action:(NSString*)action name:(nullable NSString*)name value:(nullable NSNumber*)value {
#ifdef PIWIK_ENABLED
    [self sendEventWithCategory:category action:action name:name value:value];
#endif
}

- (void)wmf_logActionPreviewInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext] action:@"Preview" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionTapThroughInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext] action:@"Tap Through" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionSaveInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext] action:@"Save" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionUnsaveInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext] action:@"Unsave" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionImpressionInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext] action:@"Impression" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionTapThroughMoreInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self sendEventWithCategory:[context analyticsContext] action:@"Tap Through More" name:[contentType analyticsContentType] value:nil];
}

- (void)wmf_logActionSwitchLanguageInContext:(id<WMFAnalyticsContextProviding>)context contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType {
    [self sendEventWithCategory:[context analyticsContext] action:@"Switch Language" name:[contentType analyticsContentType] value:nil];
}

@end

NS_ASSUME_NONNULL_END