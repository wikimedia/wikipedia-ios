//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "UIButton+WMFButton.h"

@interface UIBarButtonItem (WMFButtonConvenience)

// Returns bar button item with our UIButton as its customView.
+ (UIBarButtonItem*)wmf_buttonType:(WMFButtonType)type
                           handler:(void (^)(id sender))action;

// If self.customView is UIButton return it else return nil.
- (UIButton*)wmf_UIButton;

@end
