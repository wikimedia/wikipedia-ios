//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

- (void)transitionToRootViewController:(UIViewController*)viewController animated:(BOOL)animated;

- (void)presentRootViewController:(BOOL)animated withSplash:(BOOL)withSplash;

@end
