#import "WMFWebView.h"

@implementation WMFWebView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(_share:)) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)_share:(id)sender {
    // no-op, handle share in LegacyWebViewController
}

@end
