//  Created by Monte Hurd on 9/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+WMFOpenExternalUrl.h"
#import "SVModalWebViewController.h"

#import "Global.h"
#import "ZeroConfigState.h"
#import "SessionSingleton.h"
#import "UIAlertView+BlocksKit.h"

@implementation UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(NSURL*)url {
    [self wmf_openExternalUrl:url useSafari:NO];
}

- (void)wmf_openExternalUrl:(NSURL*)url useSafari:(BOOL)useSafari{
    NSParameterAssert(url);

    //If zero rated, don't open any external (non-zero rated!) links until user consents!
    if ([SessionSingleton sharedInstance].zeroConfigState.disposition && [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
        NSString* messageWithHost = [NSString stringWithFormat:@"%@\n\n%@", MWLocalizedString(@"zero-interstitial-leave-app", nil), url.host];
        UIAlertView* zeroAlert    = [UIAlertView bk_alertViewWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                                               message:messageWithHost];
        [zeroAlert bk_setCancelButtonWithTitle:MWLocalizedString(@"zero-interstitial-cancel", nil) handler:nil];
        [zeroAlert bk_addButtonWithTitle:MWLocalizedString(@"zero-interstitial-continue", nil) handler:^{
            [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
        }];
        [zeroAlert show];
    } else {
        [self wmf_openExternalUrlModallyIfNeeded:url forceSafari:useSafari];
    }

}


- (void)wmf_openExternalUrlModallyIfNeeded:(NSURL*)url forceSafari:(BOOL)forceSafari {
    // iOS 9 and later just use UIApplication's openURL.
    if (forceSafari || [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // pre iOS 9 use SVModalWebViewController.
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self wmf_presentExternalUrlAsSVModal:url];
            }];
            return;
        }
        [self wmf_presentExternalUrlAsSVModal:url];
    }
}

- (void)wmf_presentExternalUrlAsSVModal:(NSURL*)url {
    [self presentViewController:[[SVModalWebViewController alloc] initWithURL:url] animated:YES completion:nil];
}

@end
