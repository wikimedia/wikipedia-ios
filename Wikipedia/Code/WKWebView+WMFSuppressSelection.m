#import "WKWebView+WMFSuppressSelection.h"

@implementation WKWebView (WMF_SuppressSelection)

- (void)wmf_suppressSelection {
    self.userInteractionEnabled = NO;
    self.userInteractionEnabled = YES;
}

@end
