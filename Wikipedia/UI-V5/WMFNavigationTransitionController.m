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
#import "WMFArticleListCollectionViewController.h"
#import "WMFArticlePopupTransition.h"
#import "WMFArticleListTranstion.h"
#import "WMFArticleViewController.h"
#import "WMFArticleContainerViewController.h"

@interface UIViewController (WMFClassCheckConvenience)

- (BOOL)wmf_isArticleList;

- (BOOL)wmf_isArticleContainer;

- (BOOL)wmf_isArticleContentController;

@end


@interface WMFNavigationTransitionController ()

@end

@implementation WMFNavigationTransitionController

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:[WMFArticleListTranstion class]]) {
        WMFArticleListTranstion* listTransition = (WMFArticleListTranstion*)animationController;
        return listTransition.isDismissing ? listTransition : nil;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    if ([fromVC wmf_isArticleList] && [toVC wmf_isArticleContainer]) {
        NSAssert(operation == UINavigationControllerOperationPush, @"Expected push, got %ld", operation);
        DDLogInfo(@"Pushing container from list");
        WMFArticleListTranstion* transition =
            [self transitionForList:(WMFArticleListCollectionViewController*)fromVC
                          container:(WMFArticleContainerViewController*)toVC];
        return transition;
    } else if ([fromVC wmf_isArticleContainer] && [toVC wmf_isArticleList]) {
        NSAssert(operation == UINavigationControllerOperationPop, @"Expected pop, got %ld", operation);
        DDLogInfo(@"Popping from container to list");
        WMFArticleListTranstion* transition =
            [self transitionForList:(WMFArticleListCollectionViewController*)toVC
                          container:(WMFArticleContainerViewController*)fromVC];
        return transition;
    }
    // fall back to default
    return nil;
}

#pragma mark - Specific Transitions

- (WMFArticleListTranstion*)transitionForList:(WMFArticleListCollectionViewController*)listVC
                                     container:(WMFArticleContainerViewController*)containerVC {
    NSAssert([containerVC wmf_isArticleContainer],
             @"Expected %@ to be an article container when originating controller is a list.", containerVC);
    static const char* const WMFArticleListTranstionAssociationKey = "WMFArticleListTranstion";
    WMFArticleListTranstion* listTransition = [listVC bk_associatedValueForKey:WMFArticleListTranstionAssociationKey];
    if (!listTransition) {
        listTransition = [WMFArticleListTranstion new];
        listTransition.listViewController = listVC;
        [listVC bk_associateValue:listTransition withKey:WMFArticleListTranstionAssociationKey];
    }
    NSParameterAssert(listTransition.listViewController == listVC);
    listTransition.articleContainerViewController = containerVC;
    return listTransition;
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
