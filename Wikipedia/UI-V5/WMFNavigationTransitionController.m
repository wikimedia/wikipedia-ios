//
//  WMFNavigationTransitionController.m
//  Wikipedia
//
//  Created by Brian Gerstlenon 8/7/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNavigationTransitionController.h"
#import <UIKit/UIKit.h>

#import "WMFArticleContentController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"
#import "WMFArticlePopupTransition.h"
#import "WMFArticleViewController.h"
#import "WMFArticleContainerViewController_Transitioning.h"

@interface UIViewController (WMFClassCheckConvenience)

- (BOOL)wmf_isArticleList;

- (BOOL)wmf_isArticleContainer;

- (BOOL)wmf_isArticleContentController;

@end


@interface WMFNavigationTransitionController ()

@end

@implementation WMFNavigationTransitionController

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController*)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:[WMFArticleListTransition class]]) {
        WMFArticleListTransition* listTransition = (WMFArticleListTransition*)animationController;
        // HAX: should probably just use separate animators instead of relying on a flag being set
        return listTransition.isDismissing ? listTransition : nil;
    } else if ([animationController isKindOfClass:[WMFArticlePopupTransition class]]) {
        WMFArticlePopupTransition* popupTransition = (WMFArticlePopupTransition*)animationController;
        return popupTransition;
    } else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    if ([fromVC wmf_isArticleList] && [toVC wmf_isArticleContainer]) {
        NSAssert(operation == UINavigationControllerOperationPush, @"Expected push, got %ld", operation);
        DDLogVerbose(@"Pushing container from list");
        WMFArticleListTransition* transition =
            [self transitionForList:(WMFArticleListCollectionViewController*)fromVC
                          container:(WMFArticleContainerViewController*)toVC];
        return transition;
    } else if ([fromVC wmf_isArticleContainer]) {
        if ([toVC wmf_isArticleList]) {
            NSAssert(operation == UINavigationControllerOperationPop, @"Expected pop, got %ld", operation);
            DDLogVerbose(@"Popping from container to list");
            WMFArticleListTransition* transition =
                [self transitionForList:(WMFArticleListCollectionViewController*)toVC
                              container:(WMFArticleContainerViewController*)fromVC];
            return transition;
        } else if ([toVC wmf_isArticleContainer]) {
            DDLogVerbose(@"Transitioning between containers with operation: %ld", operation);
            NSAssert(operation != UINavigationControllerOperationNone,
                     @"UINavigationControllerOperationNone is not supported!");
            if (operation == UINavigationControllerOperationPop) {
                return [self popupTransitionWithPresentingController:(WMFArticleContainerViewController*)toVC
                                                 presentedController:(WMFArticleContainerViewController*)fromVC];
            } else if (operation == UINavigationControllerOperationPush) {
                return [self popupTransitionWithPresentingController:(WMFArticleContainerViewController*)fromVC
                                                 presentedController:(WMFArticleContainerViewController*)toVC];
            }
        }
    }
    // fall back to default
    return nil;
}

#pragma mark - Specific Transitions

- (WMFArticleListTransition*)transitionForList:(WMFArticleListCollectionViewController*)listVC
                                     container:(WMFArticleContainerViewController*)containerVC {
    listVC.listTransition.articleContainerViewController = containerVC;
    return listVC.listTransition;
}

- (WMFArticlePopupTransition*)popupTransitionWithPresentingController:(WMFArticleContainerViewController*)presentingVC
                                                  presentedController:(WMFArticleContainerViewController*)presentedVC {
    presentingVC.popupTransition.presentedViewController = presentedVC;
    return presentingVC.popupTransition;
}

@end

@implementation UIViewController (WMFClassCheckConvenience)

- (BOOL)wmf_isArticleContainer {
    return [self isKindOfClass:[WMFArticleContainerViewController class]];
}

- (BOOL)wmf_isArticleList {
    return [self isKindOfClass:[WMFArticleListCollectionViewController class]];
}

- (BOOL)wmf_isArticleContentController {
    return [self conformsToProtocol:@protocol(WMFArticleContentController)];
}

@end
