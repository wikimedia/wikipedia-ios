//  Created by Monte Hurd on 2/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class MASConstraintMaker;

@interface UIViewController (WMF_ChildViewController)

- (void)wmf_addChildController:(UIViewController*)childController
             withContainerView:(UIView*)containerView
                   constraints:(void (^)(MASConstraintMaker* makeChildControllerView))constraintsMaker;

- (void)wmf_addChildController:(UIViewController*)childController andConstrainToEdgesOfContainerView:(UIView*)containerView;

@end
