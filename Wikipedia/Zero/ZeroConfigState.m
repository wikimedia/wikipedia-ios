//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ZeroConfigState.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation ZeroConfigState

- (void)setZeroOnDialogShownOnce {
    [[NSUserDefaults standardUserDefaults] setObject:@YES
                                              forKey:@"ZeroOnDialogShownOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroOnDialogShownOnce"];
}

- (void)toggleWarnWhenLeaving {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:![self warnWhenLeaving]]
                                              forKey:@"ZeroWarnWhenLeaving"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)warnWhenLeaving {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"];
}

- (void)toggleFakeZeroOn {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:![self fakeZeroOn]]
                                              forKey:@"FakeZeroOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)fakeZeroOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FakeZeroOn"];
}

- (void)showWarningIfNeededBeforeOpeningURL:(NSURL*)url {
    NSParameterAssert(url);
    if (self.disposition && [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
        NSString* messageWithHost = [NSString stringWithFormat:@"%@\n\n%@",
                                     MWLocalizedString(@"zero-interstitial-leave-app", nil),
                                     url.host];
        UIAlertView* zeroAlert = [UIAlertView bk_alertViewWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                                            message:messageWithHost];
        [zeroAlert bk_setCancelButtonWithTitle:MWLocalizedString(@"zero-interstitial-cancel", nil)
                                       handler:nil];
        [zeroAlert bk_addButtonWithTitle:MWLocalizedString(@"zero-interstitial-continue", nil) handler:^{
            [[UIApplication sharedApplication] openURL:url];
        }];
        [zeroAlert show];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
