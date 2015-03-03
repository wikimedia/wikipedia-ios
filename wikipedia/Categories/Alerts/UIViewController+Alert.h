//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "AlertLabel.h"

// Category for showing alerts from any view controller.

@interface UIViewController (Alert)

- (void)showAlert:(id)alertText type:(AlertType)type duration:(CGFloat)duration;

- (void)fadeAlert;

- (void)hideAlert;

@end
