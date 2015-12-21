
@import PiwikTracker;
#import "WMFAnalyticsLogging.h"

@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

@interface PiwikTracker (WMFExtensions)

+ (void)wmf_start;

- (void)wmf_logView:(id<WMFAnalyticsLogging>)view;

/**
 *  For events that take a "source". Do not ever send an article VC.
 *  If you do, every article will be count as a unique source. We don't want to track that.
 *  We just want to know if a someone performed an action on a particular screen.
 */
- (void)wmf_logViewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionPreviewForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionPreviewDismissedForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionPreviewCommittedForTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionSaveTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;
- (void)wmf_logActionUnsaveTitle:(MWKTitle*)title fromSource:(nullable id<WMFAnalyticsLogging>)source;

- (void)wmf_logActionScrollToTitle:(MWKTitle*)title inHomeSection:(id<WMFAnalyticsLogging>)section;
- (void)wmf_logActionOpenTitle:(MWKTitle*)title inHomeSection:(id<WMFAnalyticsLogging>)section;
- (void)wmf_logActionOpenMoreForHomeSection:(id<WMFAnalyticsLogging>)section;


@end

NS_ASSUME_NONNULL_END