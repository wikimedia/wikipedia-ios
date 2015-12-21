
#import <UIKit/UIKit.h>
#import "WMFArticleSelectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKSite, MWKDataStore, WMFSearchViewController;

@protocol WMFSearchPresentationDelegate <WMFArticleSelectionDelegate>

- (MWKDataStore*)searchDataStore;

@end

@interface UIViewController (WMFSearchButton)

+ (void)wmf_setSearchPresentationIsAnimated:(BOOL)animated;

/**
 *  Standard way of creating a search button for installation in the receiver's toolbar or navigation bar.
 *
 *  @param delegate The delegate which provides data needed to create the search view controller.
 *
 *  @return A new bar button item which will call @c wmf_presentSearchViewController: when pressed.
 */
- (UIBarButtonItem*)wmf_searchBarButtonItemWithDelegate:(UIViewController<WMFSearchPresentationDelegate>*)delegate;

@end

NS_ASSUME_NONNULL_END
