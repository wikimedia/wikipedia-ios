
#import <UIKit/UIKit.h>
#import "WMFArticleNavigationDelegate.h"

@class MWKDataStore;
@class MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleControllerMode) {
    WMFArticleControllerModeNormal = 0,
    WMFArticleControllerModeList,
    WMFArticleControllerModePopup,
};

@interface WMFArticleViewController : UITableViewController
<WMFArticleNavigation>

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, nullable) MWKArticle* article;

@property (nonatomic, assign, readonly) WMFArticleControllerMode mode;

@property (nonatomic, weak, nullable) id<WMFArticleNavigationDelegate> articleNavigationDelegate;

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated;

- (void)updateUI;

/*
   Only exposed to allow save & read button to be selectable in popup.
 */
@property (nonatomic, strong, readonly) UIButton* saveButton;

@end

NS_ASSUME_NONNULL_END
