
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

- (void)wmf_logView:(id<WMFAnalyticsLogging>)view fromSource:(nullable id<WMFAnalyticsLogging>)source {
    NSParameterAssert([view analyticsName]);
#ifdef PIWIK_ENABLED
    if (source) {
        [self sendViewsFromArray:@[[source analyticsName], [view analyticsName]]];
    } else {
        [self sendView:[view analyticsName]];
    }
#endif
}

- (void)wmf_sendEventWithCategory:(NSString*)category action:(NSString*)action name:(nullable NSString*)name value:(nullable NSNumber*)value {
#ifdef PIWIK_ENABLED
    [self sendEventWithCategory:category action:action name:name value:value];
#endif
}

- (void)wmf_logActionPreviewFromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Preview" action:@"Shown" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionPreviewDismissedFromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Preview" action:@"Dismissed" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionPreviewCommittedFromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Preview" action:@"Converted" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionSaveTitleFromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Save" action:@"Save" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionUnsaveTitleFromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Save" action:@"Unsave" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionScrollToItemInExploreSection:(id<WMFAnalyticsLogging>)section {
    [self wmf_sendEventWithCategory:@"Explore" action:@"View Item" name:[section analyticsName] value:nil];
}

- (void)wmf_logActionOpenItemInExploreSection:(id<WMFAnalyticsLogging>)section {
    [self wmf_sendEventWithCategory:@"Explore" action:@"Open Item" name:[section analyticsName] value:nil];
}

- (void)wmf_logActionOpenMoreInExploreSection:(id<WMFAnalyticsLogging>)section {
    [self sendEventWithCategory:@"Explore" action:@"Open More Like" name:[section analyticsName] value:nil];
}

@end

NS_ASSUME_NONNULL_END