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
    NSParameterAssert(url);

    void (^ openExternalURL)(NSURL*) = ^void (NSURL* url) {
        // iOS 9 and later just use UIApplication's openURL.
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            // pre iOS 9 use SVModalWebViewController.
            void (^ presentAsSVModal)() = ^void () {
                [self presentViewController:[[SVModalWebViewController alloc] initWithURL:url] animated:YES completion:nil];
            };
            if (self.presentedViewController) {
                [self dismissViewControllerAnimated:YES completion:^{
                    presentAsSVModal();
                }];
                return;
            }
            presentAsSVModal();
        }
    };

    //If zero rated, don't open any external (non-zero rated!) links until user consents!
    if ([SessionSingleton sharedInstance].zeroConfigState.disposition && [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
        NSString* messageWithHost = [NSString stringWithFormat:@"%@\n\n%@", MWLocalizedString(@"zero-interstitial-leave-app", nil), url.host];
        UIAlertView* zeroAlert    = [UIAlertView bk_alertViewWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                                               message:messageWithHost];
        [zeroAlert bk_setCancelButtonWithTitle:MWLocalizedString(@"zero-interstitial-cancel", nil) handler:nil];
        [zeroAlert bk_addButtonWithTitle:MWLocalizedString(@"zero-interstitial-continue", nil) handler:^{
            openExternalURL(url);
        }];
        [zeroAlert show];
    } else {
        openExternalURL(url);
    }
}

@end
