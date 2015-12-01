//
//  WMFArticleContainerViewController_Transitioning.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleContainerViewController.h"

@class WMFArticlePopupTransition;

@interface WMFArticleContainerViewController ()

/**
 *  Transition used to push additional article containers onto the stack.
 */
@property (strong, nonatomic, readonly) WMFArticlePopupTransition* popupTransition;

@end
