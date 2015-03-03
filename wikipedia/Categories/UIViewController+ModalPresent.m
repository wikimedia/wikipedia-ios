//  Created by Monte Hurd on 5/28/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+ModalPresent.h"
#import "ModalMenuAndContentViewController.h"

@implementation UIViewController (PresentModal)

- (void)performModalSequeWithID:(NSString*)identifier
                transitionStyle:(UIModalTransitionStyle)style
                          block:(void (^)(id))block;
{
    ModalMenuAndContentViewController* modalMenuAndContentVC =
        [NAV.storyboard instantiateViewControllerWithIdentifier:@"ModalMenuAndContentViewController"];

    modalMenuAndContentVC.modalTransitionStyle = style;
    //modalMenuAndContentVC.title = identifier; // quick hack for debug help

    // Here so "modalStackContainsViewControllerOfClass" can check which view
    // ModalMenuAndContentViewController presented.
    modalMenuAndContentVC.truePresentingVC = self;

    modalMenuAndContentVC.sequeIdentifier = identifier;
    modalMenuAndContentVC.block           = block;
    [self presentViewController:modalMenuAndContentVC animated:YES completion:^{}];
}

@end
