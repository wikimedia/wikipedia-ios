#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKDataStore, WMFArticlePreviewDataStore, WMFSearchViewController;

@interface UIViewController (WMFSearchButton)

+ (WMFSearchViewController *)wmf_sharedSearchViewController;

/**
 *  Standard way of creating a search button for installation in the receiver's toolbar or navigation bar.
 *
 *  @return A new bar button item which will call @c wmf_showSearchAnimated: when pressed.
 */
- (UIBarButtonItem *)wmf_searchBarButtonItem;

/**
 *  Present a search view controller
 *
 *  @param animated Animate the transition
 */
- (void)wmf_showSearchAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
