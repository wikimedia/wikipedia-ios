
#import <PiwikTracker/PiwikTracker.h>
#import "WMFAnalyticsLogging.h"

@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

@interface PiwikTracker (WMFExtensions)

+ (void)wmf_start;

- (void)wmf_logView:(id<WMFAnalyticsLogging>)view fromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionPreviewFromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionPreviewDismissedFromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionPreviewCommittedFromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionSaveTitleFromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionUnsaveTitleFromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionScrollToItemInExploreSection:(id<WMFAnalyticsLogging>)section;
- (void)wmf_logActionOpenItemInExploreSection:(id<WMFAnalyticsLogging>)section;
- (void)wmf_logActionOpenMoreInExploreSection:(id<WMFAnalyticsLogging>)section;


@end

NS_ASSUME_NONNULL_END