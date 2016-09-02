#import "UIViewController+WMFOpenExternalUrl.h"
#import "SVModalWebViewController.h"

#import "Global.h"
#import "ZeroConfigState.h"
#import "SessionSingleton.h"
#import "UIAlertView+BlocksKit.h"
#import "WMFZeroConfiguration.h"
#import <SafariServices/SFSafariViewController.h>
#import "NSURL+WMFExtras.h"

@implementation UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(NSURL *)url {
    [self wmf_openExternalUrl:url useSafari:NO];
}

- (void)wmf_openExternalUrl:(NSURL *)url useSafari:(BOOL)useSafari {
    NSParameterAssert(url);

    //If zero rated, don't open any external (non-zero rated!) links until user consents!
    if ([SessionSingleton sharedInstance].zeroConfigState.disposition && [[NSUserDefaults wmf_userDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
        WMFZeroConfiguration *zeroConfiguration = [SessionSingleton sharedInstance].zeroConfigState.zeroConfiguration;
        NSString *exitDialogTitle = zeroConfiguration.exitTitle ?: MWLocalizedString(@"zero-interstitial-title", nil);
        NSString *messageWithHost = [NSString stringWithFormat:@"%@\n\n%@", zeroConfiguration.exitWarning ?: MWLocalizedString(@"zero-interstitial-leave-app", nil), url.host];

        UIAlertController *zeroAlert = [UIAlertController alertControllerWithTitle:exitDialogTitle message:messageWithHost preferredStyle:UIAlertControllerStyleAlert];
        [zeroAlert addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"zero-interstitial-cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
        [zeroAlert addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"zero-interstitial-continue", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
                                                    }]];

        if ([self isPartnerInfoConfigValid:zeroConfiguration]) {
            NSString *partnerInfoText = zeroConfiguration.partnerInfoText;
            NSURL *partnerInfoUrl = [NSURL URLWithString:zeroConfiguration.partnerInfoUrl];
            [zeroAlert addAction:[UIAlertAction actionWithTitle:partnerInfoText
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *_Nonnull action) {
                                                            [self wmf_openExternalUrlModallyIfNeeded:partnerInfoUrl forceSafari:useSafari];
                                                        }]];
        }

        [self presentViewController:zeroAlert animated:YES completion:NULL];
    } else {
        [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
    }
}

- (void)wmf_openExternalUrlModallyIfNeeded:(NSURL *)url forceSafari:(BOOL)forceSafari {
    // iOS 9 and later just use UIApplication's openURL.
    if (forceSafari) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // pre iOS 9 use SVModalWebViewController.
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

    if ([SFSafariViewController class]) {
        [self wmf_presentExternalUrlAsSFSafari:url];
    } else {
        [self wmf_presentExternalUrlAsSVModal:url];
    }
}

- (void)wmf_presentExternalUrlAsSVModal:(NSURL *)url {
    [self presentViewController:[[SVModalWebViewController alloc] initWithURL:url] animated:YES completion:nil];
}

- (void)wmf_presentExternalUrlAsSFSafari:(NSURL *)url {
    [self presentViewController:[[SFSafariViewController alloc] initWithURL:url] animated:YES completion:nil];
}

- (BOOL)isPartnerInfoConfigValid:(WMFZeroConfiguration *)config {
    return config.partnerInfoText != nil && config.partnerInfoUrl != nil;
}

@end
