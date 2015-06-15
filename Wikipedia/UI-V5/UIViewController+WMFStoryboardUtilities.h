//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIViewController (WMFStoryboardUtilities)

// returns an instance of the receiver from the initial view controller of a storyboard matching it's class storyboard
+ (instancetype)wmf_initialViewControllerFromClassStoryboard;

// storyboard name for the receiver, defaults to NSStringFromClass(self)
+ (NSString*)wmf_classStoryboardName;

// UIStoryboard from the main bundle matching wmf_classStoryboardName
+ (UIStoryboard*)wmf_classStoryboard;

@end
