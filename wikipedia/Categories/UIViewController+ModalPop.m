//  Created by Monte Hurd on 6/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+ModalPop.h"
#import "ModalMenuAndContentViewController.h"

@implementation UIViewController (ModalPop)

-(void)popModal
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        //[self.truePresentingVC dismissViewControllerAnimated:YES completion:^{}];
        id presentingVC = nil;
        SEL selector = @selector(truePresentingVC);
        if ([self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            id (*func)(id, SEL) = (void *)imp;
            presentingVC = func(self, selector);
        }
        [presentingVC dismissViewControllerAnimated:YES completion:^{}];
        //[self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

-(void)popModalToRoot
{
    // Hide the black menu which presented this view controller.
    [ROOT dismissViewControllerAnimated: YES completion: ^{}];
}

@end
