
#import "WMFArticleWebViewTransition.h"
#import "WMFArticleViewController.h"
#import "WebViewController.h"
#import "UIView+WMFShapshotting.h"

@interface WMFArticleWebViewTransition ()

@property (nonatomic, weak, readwrite) WMFArticleViewController* articleViewController;
@property (nonatomic, weak, readwrite) WebViewController* webViewController;
@property (nonatomic, assign, readwrite) BOOL isPresented;

@end

@implementation WMFArticleWebViewTransition

- (instancetype)initWithArticleViewController:(WMFArticleViewController*)articleViewController webViewController:(WebViewController*)webViewController {
    self = [super init];
    if (self) {
        _duration              = 1.0;
        _articleViewController = articleViewController;
        _webViewController     = webViewController;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresented) {
        [self animateDismiss:transitionContext];
    } else {
        [self animatePresentation:transitionContext];
    }
}

#pragma mark - Animations

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    NSUInteger animatingSection = [self indexOfSelectedSectionInArticleView];

    UIView* webView     = self.webViewController.view;
    UIView* articleView = self.articleViewController.view;

    //Add the web view the container so it will render for snapshotting
    [containerView addSubview:webView];

    //Place the article view above the webview
    [containerView insertSubview:articleView aboveSubview:webView];

    //Hide the webview behind aother view so the real UI is hidden
    UIView* background = [[UIView alloc] initWithFrame:containerView.bounds];
    background.backgroundColor = [UIColor whiteColor];
    [containerView insertSubview:background aboveSubview:self.articleViewController.view];

    //Create snapshots and add to container
    UIView* sectionSnapshot = [self snapshotViewOfArticleViewSectionHeader:animatingSection inContainer:containerView];
    UIView* webSnapshot     = [self snapshotOfWebViewBelowSectionSnapshot:sectionSnapshot inContainer:containerView];
    [containerView insertSubview:sectionSnapshot aboveSubview:webSnapshot];
    UIView* articleTopSnapshot    = [self snapshotViewOfTopOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];
    UIView* articleBottomSnapshot = [self snapshotViewOfBottomOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];

    //Calculate frames for animation
    CGRect sectionFrame      = [self frameForSectionHeaderInWebViewAtIndex:animatingSection inContainer:containerView];
    CGRect webFrame          = [transitionContext finalFrameForViewController:self.webViewController];
    CGRect articleTopFrame   = [self offscreenFrameForTopSnapshot:articleTopSnapshot];
    CGRect articleBotomFrame = [self offscreenFrameForBottomSnapshot:articleBottomSnapshot];

    [UIView animateWithDuration:self.duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        sectionSnapshot.frame = sectionFrame;
        webSnapshot.frame = webFrame;
        articleTopSnapshot.frame = articleTopFrame;
        articleBottomSnapshot.frame = articleBotomFrame;
    } completion:^(BOOL finished) {
        [sectionSnapshot removeFromSuperview];
        [webSnapshot removeFromSuperview];
        [articleTopSnapshot removeFromSuperview];
        [articleBottomSnapshot removeFromSuperview];
        [background removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        self.isPresented = ![transitionContext transitionWasCancelled];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    NSUInteger animatingSection = [self indexOfSelectedSectionInWebView];

    UIView* webView     = self.webViewController.view;
    UIView* articleView = self.articleViewController.view;

    //Add the article view the container so it will render for snapshotting
    [containerView addSubview:articleView];

    //Place the webview view above the article view
    [containerView insertSubview:webView aboveSubview:articleView];

    //Hide the webview behind aother view so the real UI is hidden
    UIView* background = [[UIView alloc] initWithFrame:containerView.bounds];
    background.backgroundColor = [UIColor whiteColor];
    [containerView insertSubview:background aboveSubview:webView];

    //Create snapshots and add to container
    UIView* sectionSnapshot = [self snapshotViewOfWebViewSectionHeaderAtIndex:animatingSection inContainer:containerView];
    UIView* webSnapshot     = [self snapshotOfWebViewInContainer:containerView];
    [containerView insertSubview:sectionSnapshot aboveSubview:webSnapshot];

    UIView* articleTopSnapshot = [self snapshotViewOfTopOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];
    articleTopSnapshot.frame = [self offscreenFrameForTopSnapshot:articleTopSnapshot];

    UIView* articleBottomSnapshot = [self snapshotViewOfBottomOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];
    articleBottomSnapshot.frame = [self offscreenFrameForBottomSnapshot:articleBottomSnapshot];

    //Calculate frames for animation
    CGRect sectionFrame      = [self frameForSectionHeaderInArticleViewAtIndex:animatingSection inContainer:containerView];
    CGRect webFrame          = [self frameForWebViewSnapShot:webSnapshot belowSectionSnapshotFrame:sectionFrame];
    CGRect articleTopFrame   = [self frameofTopOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];
    CGRect articleBotomFrame = [self framefBottomOfArticleViewWithSelectedIndex:animatingSection inContainer:containerView];

    [UIView animateWithDuration:self.duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        sectionSnapshot.frame = sectionFrame;
        webSnapshot.frame = webFrame;
        articleTopSnapshot.frame = articleTopFrame;
        articleBottomSnapshot.frame = articleBotomFrame;
    } completion:^(BOOL finished) {
        [sectionSnapshot removeFromSuperview];
        [webSnapshot removeFromSuperview];
        [articleTopSnapshot removeFromSuperview];
        [articleBottomSnapshot removeFromSuperview];
        [background removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        self.isPresented = [transitionContext transitionWasCancelled];
    }];
}

#pragma mark - Article VC

- (NSUInteger)indexOfSelectedSectionInArticleView {
    return [self.articleViewController selectedSectionIndexForTransition:self];
}

- (UIView*)sectionHeaderFromArticleViewAtIndex:(NSUInteger)index {
    return [self.articleViewController transition:self viewForSectionIndex:index];
}

- (CGRect)frameForSectionHeaderInArticleViewAtIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* section = [self sectionHeaderFromArticleViewAtIndex:index];
    CGRect r        = [containerView convertRect:section.frame fromView:section.superview];
    return r;
}

- (UIView*)snapshotViewOfArticleViewSectionHeader:(NSUInteger)index inContainer:(UIView*)containerView {
    return [[self sectionHeaderFromArticleViewAtIndex:index] wmf_snapshotAfterScreenUpdates:YES andAddToContainerView:containerView];
}

- (CGRect)frameofTopOfArticleViewWithSelectedIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* original = [self.articleViewController viewForTransition:self];

    CGRect originalFrame  = original.bounds;
    CGRect frameForHeader = [self sectionHeaderFromArticleViewAtIndex:index].frame;
    CGRect topFrame       = originalFrame;
    topFrame.size.height = frameForHeader.origin.y;
    return topFrame;
}

- (UIView*)snapshotViewOfTopOfArticleViewWithSelectedIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* original = [self.articleViewController viewForTransition:self];
    CGRect topFrame  = [self frameofTopOfArticleViewWithSelectedIndex:index inContainer:containerView];
    return [original wmf_resizableSnapshotViewFromRect:topFrame afterScreenUpdates:YES andAddToContainerView:containerView];
}

- (CGRect)framefBottomOfArticleViewWithSelectedIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* original = [self.articleViewController viewForTransition:self];

    CGRect originalFrame  = original.bounds;
    CGRect frameForHeader = [self sectionHeaderFromArticleViewAtIndex:index].frame;
    CGRect bottomFrame    = originalFrame;
    bottomFrame.origin.y    = CGRectGetMaxY(frameForHeader);
    bottomFrame.size.height = bottomFrame.size.height - bottomFrame.origin.y;
    return bottomFrame;
}

- (UIView*)snapshotViewOfBottomOfArticleViewWithSelectedIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* original = [self.articleViewController viewForTransition:self];

    CGRect originalFrame  = original.bounds;
    CGRect frameForHeader = [self sectionHeaderFromArticleViewAtIndex:index].frame;
    CGRect bottomFrame    = originalFrame;
    bottomFrame.origin.y    = CGRectGetMaxY(frameForHeader);
    bottomFrame.size.height = bottomFrame.size.height - bottomFrame.origin.y;

    return [original wmf_resizableSnapshotViewFromRect:bottomFrame afterScreenUpdates:YES andAddToContainerView:containerView];
}

- (CGRect)offscreenFrameForTopSnapshot:(UIView*)view {
    CGRect frame = view.frame;
    frame.origin.y = frame.origin.y - frame.size.height;
    return frame;
}

- (CGRect)offscreenFrameForBottomSnapshot:(UIView*)view {
    CGRect frame = view.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    return frame;
}

#pragma mark - Web VC

- (NSUInteger)indexOfSelectedSectionInWebView {
    return [self.webViewController selectedSectionIndexForTransition:self];
}

- (UIView*)sectionHeaderFromWebiewAtIndex:(NSUInteger)index {
    return [self.webViewController transition:self viewForSectionIndex:index];
}

- (CGRect)frameForSectionHeaderInWebViewAtIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    UIView* section = [self sectionHeaderFromWebiewAtIndex:index];
    CGRect r        = [containerView convertRect:section.frame fromView:section.superview];
    r.origin.y -= 20; //hack until we fix up the web view hierarchy
    return r;
}

- (CGRect)frameForWebViewSnapShot:(UIView*)snapshot belowSectionSnapshotFrame:(CGRect)sectionSnapshotFrame {
    CGRect frame = snapshot.frame;
    frame.origin.x = sectionSnapshotFrame.origin.x;
    frame.origin.y = CGRectGetMinY(sectionSnapshotFrame);
    return frame;
}

- (CGRect)frameForWebViewInContainer:(UIView*)containerView {
    UIView* webView = [self.webViewController viewForTransition:self];
    CGRect r        = [containerView convertRect:webView.frame fromView:webView.superview];
    return r;
}

- (UIView*)snapshotViewOfWebViewSectionHeaderAtIndex:(NSUInteger)index inContainer:(UIView*)containerView {
    return [[self sectionHeaderFromWebiewAtIndex:index] wmf_snapshotAfterScreenUpdates:NO andAddToContainerView:containerView];
}

- (UIView*)snapshotOfWebViewInContainer:(UIView*)containerView {
    return [self.webViewController.view wmf_snapshotAfterScreenUpdates:YES andAddToContainerView:containerView];
}

- (UIView*)snapshotOfWebViewBelowSectionSnapshot:(UIView*)sectionSnapshot inContainer:(UIView*)containerView {
    UIView* snapshot = [self snapshotOfWebViewInContainer:containerView];
    snapshot.frame = [self frameForWebViewSnapShot:snapshot belowSectionSnapshotFrame:sectionSnapshot.frame];
    return snapshot;
}

@end
