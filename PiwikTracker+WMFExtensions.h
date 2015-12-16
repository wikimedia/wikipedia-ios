
@import PiwikTracker;
#import "WMFAnalyticsLogging.h"

@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

@interface PiwikTracker (WMFExtensions)

+ (void)wmf_start;

- (void)wmf_logView:(id<WMFAnalyticsLogging>)view;

- (void)wmf_logPreviewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logViewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;

@end

NS_ASSUME_NONNULL_END