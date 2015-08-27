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
#import "WMFArticleViewController.h"
#import "WMFArticleContainerViewController_Transitioning.h"

@interface UIViewController (WMFClassCheckConvenience)

- (BOOL)wmf_isListTransitionProvider;

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
        return listTransition.isDismissing ? listTransition : nil;
    } else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    return nil;

    //TODO: re-enable old logic to support all transitions
    if ([fromVC wmf_isListTransitionProvider] && [toVC wmf_isArticleContainer]) {
        NSAssert(operation == UINavigationControllerOperationPush, @"Expected push, got %ld", operation);
        DDLogVerbose(@"Pushing container from list");
        WMFArticleListTransition* transition =
            [self transitionForList:(id < WMFArticleListTransitionProvider >) fromVC
                          container:(WMFArticleContainerViewController*)toVC];
        return transition;
    } else if ([fromVC wmf_isArticleContainer]) {
        if ([toVC wmf_isListTransitionProvider]) {
            NSAssert(operation == UINavigationControllerOperationPop, @"Expected pop, got %ld", operation);
            DDLogVerbose(@"Popping from container to list");
            WMFArticleListTransition* transition =
                [self transitionForList:(id < WMFArticleListTransitionProvider >) toVC
                              container:(WMFArticleContainerViewController*)fromVC];
            return transition;
        }
    }
    // fall back to default
    return nil;
}

#pragma mark - Specific Transitions

- (WMFArticleListTransition*)transitionForList:(id<WMFArticleListTransitionProvider>)listTransitionProvider
                                     container:(WMFArticleContainerViewController*)containerVC {
    listTransitionProvider.listTransition.articleContainerViewController = containerVC;
    return listTransitionProvider.listTransition;
}

@end

@implementation UIViewController (WMFClassCheckConvenience)

- (BOOL)wmf_isArticleContainer {
    return [self isKindOfClass:[WMFArticleContainerViewController class]];
}

- (BOOL)wmf_isListTransitionProvider {
    return [self conformsToProtocol:@protocol(WMFArticleListTransitionProvider)];
}

- (BOOL)wmf_isArticleContentController {
    return [self conformsToProtocol:@protocol(WMFArticleContentController)];
}

@end
