//  Created by Monte Hurd on 9/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+WMFOpenExternalUrl.h"
#import "SVModalWebViewController.h"

#import "Global.h"
#import "ZeroConfigState.h"
#import "SessionSingleton.h"
#import "UIAlertView+BlocksKit.h"
#import "WMFZeroMessage.h"
#import <SafariServices/SFSafariViewController.h>
#import "NSURL+WMFExtras.h"

@implementation UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(NSURL*)url {
    [self wmf_openExternalUrl:url useSafari:NO];
}

- (void)wmf_openExternalUrl:(NSURL*)url useSafari:(BOOL)useSafari {
    NSParameterAssert(url);
    
    //If zero rated, don't open any external (non-zero rated!) links until user consents!
    if ([SessionSingleton sharedInstance].zeroConfigState.disposition && [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
        WMFZeroMessage* zeroMessage = [SessionSingleton sharedInstance].zeroConfigState.zeroMessage;
        NSString* exitDialogTitle   = zeroMessage.exitTitle ? : MWLocalizedString(@"zero-interstitial-title", nil);
        NSString* messageWithHost   = [NSString stringWithFormat:@"%@\n\n%@", zeroMessage.exitWarning ? : MWLocalizedString(@"zero-interstitial-leave-app", nil), url.host];
        
        UIAlertView* zeroAlert = [UIAlertView bk_alertViewWithTitle:exitDialogTitle
                                                            message:messageWithHost];
        [zeroAlert bk_setCancelButtonWithTitle:MWLocalizedString(@"zero-interstitial-cancel", nil) handler:nil];
        [zeroAlert bk_addButtonWithTitle:MWLocalizedString(@"zero-interstitial-continue", nil) handler:^{
            [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
        }];
        if ([self isPartnerInfoConfigValid:zeroMessage]) {
            NSString* partnerInfoText = zeroMessage.partnerInfoText;
            NSURL* partnerInfoUrl     = [NSURL URLWithString:zeroMessage.partnerInfoUrl];
            [zeroAlert bk_addButtonWithTitle:partnerInfoText handler:^{
                [self wmf_openExternalUrlModallyIfNeeded:partnerInfoUrl forceSafari:useSafari];
            }];
        }
        
        [zeroAlert show];
    } else {
        [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
    }
}

- (void)wmf_openExternalUrlModallyIfNeeded:(NSURL*)url forceSafari:(BOOL)forceSafari {
    // iOS 9 and later just use UIApplication's openURL.
    if (forceSafari) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // pre iOS 9 use SVModalWebViewController.
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
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
    if (!scheme || (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"]) || url.host.length == 0) {
        DDLogError(@"Attempted to open invalid external URL: %@", url);
        return;
    }
    
    if ([SFSafariViewController class]) {
        [self wmf_presentExternalUrlAsSFSafari:url];
    } else {
        [self wmf_presentExternalUrlAsSVModal:url];
    }
}

- (void)wmf_presentExternalUrlAsSVModal:(NSURL*)url {
    [self presentViewController:[[SVModalWebViewController alloc] initWithURL:url] animated:YES completion:nil];
}

- (void)wmf_presentExternalUrlAsSFSafari:(NSURL*)url {
    [self presentViewController:[[SFSafariViewController alloc] initWithURL:url] animated:YES completion:nil];
}

- (BOOL)isPartnerInfoConfigValid:(WMFZeroMessage*)msg {
    return msg.partnerInfoText != nil && msg.partnerInfoUrl != nil;
}

@end
