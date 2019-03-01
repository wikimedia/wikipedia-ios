#import "UIViewController+WMFOpenExternalUrl.h"
@import WMF;
@import SafariServices;

@implementation UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(NSURL *)url {
    [self wmf_openExternalUrl:url useSafari:NO];
}

- (void)wmf_openExternalUrl:(NSURL *)url useSafari:(BOOL)useSafari {
    NSParameterAssert(url);
    if (!url) {
        return;
    }
    [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
}

- (void)wmf_openExternalUrlModallyIfNeeded:(NSURL *)url forceSafari:(BOOL)forceSafari {
    url = url.wmf_URLByMakingiOSCompatibilityAdjustments;

    if (forceSafari || [url.scheme.lowercaseString isEqualToString:@"mailto"]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
    } else {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES
                                     completion:^{
                                         [self wmf_presentExternalUrlWithinApp:url];
                                     }];
            return;
        }
        [self wmf_presentExternalUrlWithinApp:url];
    }
}

- (void)wmf_presentExternalUrlWithinApp:(NSURL *)url {
    url = [url wmf_urlByPrependingSchemeIfSchemeless];
    NSString *scheme = url.scheme.lowercaseString;
    if (scheme.length == 0 || (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"]) || url.host.length == 0) {
        DDLogError(@"Attempted to open invalid external URL: %@", url);
        return;
    }

    [self wmf_presentExternalUrlAsSFSafari:url];
}

- (void)wmf_presentExternalUrlAsSFSafari:(NSURL *)url {
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
