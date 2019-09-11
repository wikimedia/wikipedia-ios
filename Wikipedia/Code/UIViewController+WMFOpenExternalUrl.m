#import "UIViewController+WMFOpenExternalUrl.h"
@import WMF;

@implementation UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(nullable NSURL *)url {
    [self wmf_openExternalUrl:url useSafari:NO];
}

- (void)wmf_openExternalUrl:(nullable NSURL *)url useSafari:(BOOL)useSafari {
    NSParameterAssert(url);
    if (!url) {
        return;
    }
    url = url.wmf_URLByMakingiOSCompatibilityAdjustments;
    // Routing all external URLs to Safari to fix https://phabricator.wikimedia.org/T232648
    // Preserve the forceSafari
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
}


@end
