#import "WKWebView+WMFTrackingView.h"
#import "UIView+WMFSearchSubviews.h"

@implementation WKWebView (TrackingView)

- (UIView *)wmf_browserView {
  return [self.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"WKContentView")];
}

@end
