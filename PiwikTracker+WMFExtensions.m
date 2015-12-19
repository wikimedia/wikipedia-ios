
#import "PiwikTracker+WMFExtensions.h"
#import "MWKTitle+WMFAnalyticsLogging.h"

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

- (void)wmf_logView:(id<WMFAnalyticsLogging>)view {
    NSParameterAssert([view analyticsName]);
#ifdef PIWIK_ENABLED
    [self sendView:[view analyticsName]];
#endif
}

- (void)wmf_logViewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source {
    NSParameterAssert([title analyticsName]);
#ifdef PIWIK_ENABLED
    if (source) {
        [self sendViewsFromArray:@[[source analyticsName], @"Article", [title analyticsName]]];
    } else {
        [self sendViewsFromArray:@[@"Article", [title analyticsName]]];
    }
#endif
}


- (void)wmf_sendEventWithCategory:(NSString*)category action:(NSString*)action name:(nullable NSString*)name value:(nullable NSNumber*)value {
#ifdef PIWIK_ENABLED
    [self sendEventWithCategory:category action:action name:name value:value];
#endif
}

- (void)wmf_logActionPreviewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Preview" action:@"Shown" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionPreviewDismissedForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source{
    [self wmf_sendEventWithCategory:@"Preview" action:@"Dismissed" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionPreviewCommittedForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source{
    [self wmf_sendEventWithCategory:@"Preview" action:@"Converted" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionSaveTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Save" action:@"Save" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionUnsaveTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source {
    [self wmf_sendEventWithCategory:@"Save" action:@"Unsave" name:[source analyticsName] value:nil];
}

- (void)wmf_logActionScrollToTitle:(MWKTitle*)title inHomeSection:(id<WMFAnalyticsLogging>)section{
    [self wmf_sendEventWithCategory:@"Home" action:@"View Article" name:[section analyticsName] value:nil];
}

- (void)wmf_logActionOpenTitle:(MWKTitle*)title inHomeSection:(id<WMFAnalyticsLogging>)section{
    [self wmf_sendEventWithCategory:@"Home" action:@"Open Article" name:[section analyticsName] value:nil];
}

- (void)wmf_logActionOpenMoreForHomeSection:(id<WMFAnalyticsLogging>)section {
    [self sendEventWithCategory:@"Home" action:@"Open More Like" name:[section analyticsName] value:nil];
}

@end

NS_ASSUME_NONNULL_END