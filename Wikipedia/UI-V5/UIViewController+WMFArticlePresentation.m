//
//  UIViewController+WMFArticlePresentation.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFArticlePresentation.h"
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageList.h"
#import "MWKUserDataStore.h"
#import "WMFArticleContainerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewHandler : NSObject
    <UIViewControllerPreviewingDelegate>

@property (nonatomic, weak) id<WMFArticlePreviewingDelegate> delegate;
@property (nonatomic, assign) MWKHistoryDiscoveryMethod previewDiscoveryMethod;
@property (nonatomic, weak) UIViewController* sourceViewController;

@end

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleViewControllerWithTitle:(MWKTitle*)title
                               discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                                     dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    WMFArticleContainerViewController* articleContainerVC =
        [[WMFArticleContainerViewController alloc] initWithArticleTitle:title dataStore:dataStore];
    [self wmf_pushArticleViewController:articleContainerVC discoveryMethod:discoveryMethod];
}

- (void)wmf_previewTitlesInView:(UIView*)view delegate:(id<WMFArticlePreviewingDelegate>)delegate {
    WMFArticlePreviewHandler* handler = [WMFArticlePreviewHandler new];
    handler.delegate             = delegate;
    handler.sourceViewController = self;
    [self registerForPreviewingWithDelegate:handler sourceView:view];
}

- (void)wmf_pushArticleViewController:(WMFArticleContainerViewController*)articleViewController
                      discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod  {
    MWKHistoryList* historyList = articleViewController.dataStore.userDataStore.historyList;
    [historyList addPageToHistoryWithTitle:articleViewController.articleTitle discoveryMethod:discoveryMethod];
    [historyList save];
    [self.navigationController pushViewController:articleViewController animated:YES];
}

@end

@implementation WMFArticlePreviewTuple

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    self = [super init];
    if (self) {
        self.previewedTitle  = title;
        self.discoveryMethod = discoveryMethod;
    }
    return self;
}

@end

@implementation WMFArticlePreviewHandler

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    WMFArticlePreviewTuple* previewData = [self.delegate previewDataForTitleAtPoint:location
                                                                             inView:previewingContext.sourceView];
    if (!previewData) {
        return nil;
    }

    self.previewDiscoveryMethod = previewData.discoveryMethod;

    return [[WMFArticleContainerViewController alloc] initWithArticleTitle:previewData.previewedTitle
                                                                 dataStore:[self.delegate dataStore]];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(WMFArticleContainerViewController*)viewControllerToCommit {
    [self.sourceViewController wmf_pushArticleViewController:viewControllerToCommit
                                             discoveryMethod:self.previewDiscoveryMethod];
}

@end

NS_ASSUME_NONNULL_END
