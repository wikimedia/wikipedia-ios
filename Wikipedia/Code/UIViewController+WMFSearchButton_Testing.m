//
//  UIViewController+WMFSearchButton_Testing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFSearchButton_Testing.h"
#import "WMFSearchViewController.h"

WMFSearchViewController* _sharedSearchViewController = nil;

@implementation UIViewController (WMFSearchButton_Testing)

+ (void)wmfSearchButton_resetSharedSearchButton {
    if (!_sharedSearchViewController.view.window) {
        _sharedSearchViewController = nil;
    }
}

@end
