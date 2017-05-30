#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKDataStore, WMFSearchViewController;

@interface WMFSearchButton : UIBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic) CGFloat alpha;

@end

@interface UIViewController (WMFSearchButton)

+ (WMFSearchViewController *)wmf_sharedSearchViewController;

/**
 *  This datastore is passed to the search VC
 *
 *  @param dataStore The datastore
 */
+ (void)wmf_setSearchButtonDataStore:(MWKDataStore *)dataStore;

/**
 *  Standard way of creating a search button for installation in the receiver's toolbar or navigation bar.
 *
 *  @return A new bar button item which will call @c wmf_showSearchAnimated: when pressed.
 */
- (WMFSearchButton *)wmf_searchBarButtonItem;

/**
 *  Present a search view controller
 *
 *  @param animated Animate the transition
 */
- (void)wmf_showSearchAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
