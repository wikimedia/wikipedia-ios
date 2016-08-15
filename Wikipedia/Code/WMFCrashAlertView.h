//
//  WMFCrashAlertView.h
//  Wikipedia
//
//  Created by Adam Baso on 3/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const WMFHockeyAppServiceName;

@interface WMFCrashAlertView : UIAlertView

+ (NSString *)wmf_hockeyAppPrivacyButtonText;

@end
