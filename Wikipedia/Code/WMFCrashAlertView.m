//
//  WMFCrashAlertView.m
//  Wikipedia
//
//  Created by Adam Baso on 3/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFCrashAlertView.h"
#import "WikipediaAppUtils.h"

NSString *const WMFHockeyAppServiceName = @"HockeyApp";
NSString *const kHockeyAppPrivacyStringsKey = @"hockeyapp-alert-privacy";
NSString *const kHockyAppPrivacyUrl = @"http://hockeyapp.net/privacy/";

@implementation WMFCrashAlertView

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    NSString *buttonText = [self buttonTitleAtIndex:buttonIndex];
    if ([buttonText isEqualToString:[WMFCrashAlertView wmf_hockeyAppPrivacyButtonText]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kHockyAppPrivacyUrl]];
        return;
    }
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

+ (NSString *)wmf_hockeyAppPrivacyButtonText {
    return [MWLocalizedString(kHockeyAppPrivacyStringsKey, nil)
        stringByReplacingOccurrencesOfString:@"$1"
                                  withString:WMFHockeyAppServiceName];
}

@end
