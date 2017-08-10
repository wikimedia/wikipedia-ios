#import <WMF/PiwikTracker+WMFExtensions.h>
#import <WMF/NSBundle+WMFInfoUtils.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PiwikTracker (WMFExtensions)

+ (void)wmf_start {
    static NSTimeInterval const WMFDispatchInterval = 60;
    NSString *piwikHostURLString = @"https://piwik.wikimedia.org/";
    NSString *appID = @"3";
    [PiwikTracker sharedInstanceWithSiteID:appID baseURL:[NSURL URLWithString:piwikHostURLString]];
    [[PiwikTracker sharedInstance] setDispatchInterval:WMFDispatchInterval];
    [[PiwikTracker sharedInstance] setSampleRate:10];
    [[[PiwikTracker sharedInstance] dispatcher] setUserAgent:[WikipediaAppUtils versionedUserAgent]];
}

- (void)wmf_logView:(id<WMFAnalyticsViewNameProviding>)view {
    NSParameterAssert([view analyticsName]);
#ifdef PIWIK_ENABLED
    [self sendView:[view analyticsName]];
#endif
}

- (void)wmf_sendEventWithCategory:(NSString *)category action:(NSString *)action name:(NSString *)name value:(nullable NSNumber *)value {
#ifdef PIWIK_ENABLED
    [self sendEventWithCategory:category
                         action:action
                           name:name
                          value:value];
#endif
}

- (void)wmf_logAction:(NSString *)action inContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:action
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionPreviewInContext:(id<WMFAnalyticsContextProviding>)context
                          contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_logActionPreviewInContext:context contentType:contentType date:nil];
}

- (void)wmf_logActionPreviewInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType date:(nullable NSDate *)date {

    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Preview"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionTapThroughInContext:(id<WMFAnalyticsContextProviding>)context
                             contentType:(id<WMFAnalyticsContentTypeProviding>)contentType
                                   value:(id<WMFAnalyticsValueProviding>)value {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Tap Through"
                               name:[contentType analyticsContentType]
                              value:[value analyticsValue]];
}

- (void)wmf_logActionTapThroughInContext:(id<WMFAnalyticsContextProviding>)context
                             contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_logActionTapThroughInContext:context contentType:contentType value:nil];
}

- (void)wmf_logActionSaveInContext:(id<WMFAnalyticsContextProviding>)context
                       contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Save"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionShareInContext:(id<WMFAnalyticsContextProviding>)context
                        contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Share"
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
    [self wmf_logActionImpressionInContext:context contentType:contentType value:nil];
}

- (void)wmf_logActionImpressionInContext:(id<WMFAnalyticsContextProviding>)context
                             contentType:(id<WMFAnalyticsContentTypeProviding>)contentType
                                   value:(id<WMFAnalyticsValueProviding>)value {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Impression"
                               name:[contentType analyticsContentType]
                              value:[value analyticsValue]];
}

- (void)wmf_logActionTapThroughMoreInContext:(id<WMFAnalyticsContextProviding>)context
                                 contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_logActionTapThroughMoreInContext:context contentType:contentType value:nil];
}

- (void)wmf_logActionTapThroughMoreInContext:(id<WMFAnalyticsContextProviding>)context
                                 contentType:(id<WMFAnalyticsContentTypeProviding>)contentType
                                       value:(id<WMFAnalyticsValueProviding>)value {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Tap Through More"
                               name:[contentType analyticsContentType]
                              value:[value analyticsValue]];
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

- (void)wmf_logActionPushInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType date:(nullable NSDate *)date {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Push"
                               name:[contentType analyticsContentType]
                              value:[self hourTimeValueFromDate:date]];
}

- (void)wmf_logActionDismissInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType value:(id<WMFAnalyticsValueProviding>)value {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Disable"
                               name:[contentType analyticsContentType]
                              value:[value analyticsValue]];
}

- (void)wmf_logActionSwitchThemeInContext:(id<WMFAnalyticsContextProviding>)context
                              contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Theme Change"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionEnableImageDimmingInContext:(id<WMFAnalyticsContextProviding>)context
                                     contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Enable Dimming"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionDisableImageDimmingInContext:(id<WMFAnalyticsContextProviding>)context
                                      contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Disable Dimming"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (void)wmf_logActionAdjustBrightnessInContext:(id<WMFAnalyticsContextProviding>)context
                                   contentType:(id<WMFAnalyticsContentTypeProviding>)contentType {
    [self wmf_sendEventWithCategory:[context analyticsContext]
                             action:@"Adjust Brightness"
                               name:[contentType analyticsContentType]
                              value:nil];
}

- (NSNumber *)hourTimeValueFromDate:(nullable NSDate *)date {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:date];
    return @(hour);
}

@end

NS_ASSUME_NONNULL_END
