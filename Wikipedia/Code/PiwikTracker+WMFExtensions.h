#import <PiwikTracker/PiwikTracker.h>
#import "WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN

@interface PiwikTracker (WMFExtensions)

+ (void)wmf_start;

+ (instancetype)wmf_configuredInstance;

- (void)wmf_logView:(id<WMFAnalyticsViewNameProviding>)view;

- (void)wmf_logActionImpressionInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;
- (void)wmf_logActionPreviewInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;
- (void)wmf_logActionTapThroughInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;

- (void)wmf_logActionTapThroughMoreInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;

- (void)wmf_logActionSaveInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;
- (void)wmf_logActionUnsaveInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;
- (void)wmf_logActionSwitchLanguageInContext:(id<WMFAnalyticsContextProviding>)context contentType:(id<WMFAnalyticsContentTypeProviding>)contentType;

@end

NS_ASSUME_NONNULL_END
