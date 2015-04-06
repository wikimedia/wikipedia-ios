//  Created by Monte Hurd on 2/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+WMFChildViewController.h"
#import <Masonry/Masonry.h>

@implementation UIViewController (WMF_ChildViewController)

- (void)wmf_addChildController:(UIViewController*)childController andConstrainToEdgesOfContainerView:(UIView*)containerView {
    [self addChildViewController:childController];

    [containerView addSubview:childController.view];

    [childController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        // IMPORTANT: must use "leading" and "trailing" not "left" and "right"
        // (or "make.edges.equalTo").
        // This because leading and trailing respect language direction.
        make.leading.trailing.top.and.bottom.equalTo(containerView);
    }];

    [childController didMoveToParentViewController:self];
}

@end
