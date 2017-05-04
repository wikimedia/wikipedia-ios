#import "UIViewController+WMFOpenExternalUrl.h"

#import "Global.h"
#import "WMFZeroConfigurationManager.h"
#import "SessionSingleton.h"
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
    if ([SessionSingleton sharedInstance].zeroConfigurationManager.isZeroRated && [[NSUserDefaults wmf_userDefaults] boolForKey:WMFZeroWarnWhenLeaving]) {
        WMFZeroConfiguration *zeroConfiguration = [SessionSingleton sharedInstance].zeroConfigurationManager.zeroConfiguration;
        NSString *exitDialogTitle = zeroConfiguration.exitTitle ?: WMFLocalizedStringWithDefaultValue(@"zero-interstitial-title", nil, nil, @"Leaving Wikipedia Zero", @"Alert text for leaving Wikipedia Zero");
        NSString *messageWithHost = [NSString stringWithFormat:@"%@\n\n%@", zeroConfiguration.exitWarning ?: WMFLocalizedStringWithDefaultValue(@"zero-interstitial-leave-app", nil, nil, @"Data charges may apply. Continue to external site?", @"Alert text shown if Wikipedia Zero free data access is enabled and user taps external link"), url.host];

        UIAlertController *zeroAlert = [UIAlertController alertControllerWithTitle:exitDialogTitle message:messageWithHost preferredStyle:UIAlertControllerStyleAlert];
        [zeroAlert addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-interstitial-cancel", nil, nil, @"Stay here", @"Button text to not continue to external site.\n{{Identical|Stay here}}") style:UIAlertActionStyleCancel handler:NULL]];
        [zeroAlert addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-interstitial-continue", nil, nil, @"Leave", @"Button text confirming user wants to continue to external site.\n{{Identical|Leave}}")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
                                                    }]];

        if ([zeroConfiguration hasPartnerInfoTextAndURL]) {
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
    if (forceSafari || [url.scheme.lowercaseString isEqualToString:@"mailto"]) {
        [[UIApplication sharedApplication] openURL:url];
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
    [self presentViewController:[[SFSafariViewController alloc] initWithURL:url] animated:YES completion:nil];
}

@end
