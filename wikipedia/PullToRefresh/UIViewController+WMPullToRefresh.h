
#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

typedef NS_ENUM(NSUInteger, WMPullToRefreshProgressType){
    
    WMPullToRefreshProgressTypeIndeterminate,
    WMPullToRefreshProgressTypeDeterminate
};

/**
 *  Use this category to add pull to refresh to any view controller with a scroll view.
 *  Each view controller is responsible for implementing the SSPullToRefreshViewDelegate methods.
 */
@interface UIViewController (WMPullToRefresh)<SSPullToRefreshViewDelegate>

/**
 *  Setup pull to refresh
 *
 *  @param type       Indeterminate or determinate progress
 *  @param scrollView The scroll view to add the pull to refresh to
 */
- (void)setupPullToRefreshWithType:(WMPullToRefreshProgressType)type inScrollView:(UIScrollView*)scrollView;

/**
 *  Configuration - note, configuring these prior to calling the setup method will result in a nonop
 */
@property (strong, nonatomic) NSString *refreshPromptString;
@property (strong, nonatomic) NSString *refreshReleaseString;
@property (strong, nonatomic) NSString *refreshRunningString;

/**
 *  Call to return the pull to refresh view to normal state (collapse)
 */
- (void)finishRefreshing;

/**
 *  Call to tear down - should be in dealloc of your view controller
 */
- (void)tearDownPullToRefresh;


@end
