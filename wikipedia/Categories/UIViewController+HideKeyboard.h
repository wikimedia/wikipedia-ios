//  Created by Monte Hurd on 2/3/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIViewController (HideKeyboard)

// Checks every controller's subviews recursively to determine which view may
// be responsible for the keyboard being onscreen - then sends message to that
// view to hide the keyboard.
- (void)hideKeyboard;

@end
