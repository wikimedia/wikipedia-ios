
#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"
#import "WMPullToRefreshContentView.h"

/**
 *  Use this category to add pull to refresh to any view controller with a scroll view.
 *  Each view controller is responsible for implementing the SSPullToRefreshViewDelegate methods.
 */
@interface UIViewController (WMPullToRefresh)<SSPullToRefreshViewDelegate>

/**
 *  Setup pull to refresh and specify the type of pull to refresh view
 *
 *  @param type       Indeterminate or determinate progress
 *  @param scrollView The scroll view to add the pull to refresh to
 */
- (void)setupPullToRefreshWithType:(WMPullToRefreshProgressType)type inScrollView:(UIScrollView*)scrollView;

/**
 *  Configuration strings - Configuring these prior to calling the setup method will result in a nonop.
 */
@property (strong, nonatomic) NSString *refreshPromptString;
@property (strong, nonatomic) NSString *refreshReleaseString;
@property (strong, nonatomic) NSString *refreshRunningString;

/**
 *  Update progress. Only valid for WMPullToRefreshProgressTypeDeterminate. Calling on when state is indeterminate will result in a nonop
 *
 *  @param progress Set the progress (0…1.0)
 *  @param animated Animate the progress change
 */
- (void)setRefreshProgress:(float)progress animated:(BOOL)animated;

/**
 *  Execute a block when the cancel button is tapped. Only executed when type is WMPullToRefreshProgressTypeDeterminate.
 *  This block should call finishRefreshing after the cancelling any operations
 */
@property (copy, nonatomic) dispatch_block_t refreshCancelBlock;

/**
 *  Call to return the pull to refresh view to normal state (collapse) - when refresh is completed/cancelled
 */
- (void)finishRefreshing;

/**
 *  Call to tear down - This can be called at anytime, but generally should be called in the dealloc method of your view controller */
- (void)tearDownPullToRefresh;


@end
