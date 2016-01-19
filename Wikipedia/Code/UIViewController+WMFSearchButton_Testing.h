//
//  UIViewController+WMFSearchButton_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+WMFSearch.h"

@class WMFSearchViewController;
extern WMFSearchViewController* _sharedSearchViewController;

@interface UIViewController (WMFSearchButton_Testing)

+ (void)wmfSearchButton_resetSharedSearchButton;

@end
