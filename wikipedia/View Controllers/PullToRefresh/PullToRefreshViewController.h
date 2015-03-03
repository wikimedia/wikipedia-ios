//  Created by Brion on 7/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface PullToRefreshViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIView* pullToRefreshView;

/**
 * If you override this, you must call the super!
 */
- (void)scrollViewDidScroll:(UIScrollView*)scrollView;

/**
 * Returns the scroll view to operate on.
 * Defaults to self.view
 */
- (UIScrollView*)refreshScrollView;

/**
 * Get a localized string to show when pulling, before activation
 */
- (NSString*)refreshPromptString;

/**
 * Get a localized string to show during refresh
 */
- (NSString*)refreshRunningString;

/**
 * Called when the custom pull-to-refresh control is triggered
 */
- (void)refreshWasPulled;

/**
 * Allows for disabling the refresh behavior
 */
- (BOOL)refreshShouldShow;

@end
