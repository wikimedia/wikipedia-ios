
@import UIKit;

@class WMFArticleViewController;
@class WebViewController;

@protocol WMFArticleWebViewTransitioning;

@interface WMFArticleWebViewTransition : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

- (instancetype)initWithArticleViewController:(WMFArticleViewController*)articleViewController webViewController:(WebViewController*)webViewController;

@property (nonatomic, weak, readonly) WMFArticleViewController* articleViewController;
@property (nonatomic, weak, readonly) WebViewController* webViewController;

@property (nonatomic, assign) NSTimeInterval duration;

@end


@protocol WMFArticleWebViewTransitioning <NSObject>

- (NSUInteger)selectedSectionIndexForTransition:(WMFArticleWebViewTransition*)transition;
- (UIView*)viewForTransition:(WMFArticleWebViewTransition*)transition;
- (UIView*)transition:(WMFArticleWebViewTransition*)transition viewForSectionIndex:(NSUInteger)index;

@end
